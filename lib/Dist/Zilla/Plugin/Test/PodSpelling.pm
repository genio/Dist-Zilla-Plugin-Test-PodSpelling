package Dist::Zilla::Plugin::Test::PodSpelling;
use 5.008;
use strict;
use warnings;
BEGIN {
	# VERSION
}

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::TextTemplate';

sub mvp_multivalue_args { return qw( stopwords ) }

has wordlist => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Pod::Wordlist::hanekomu',    # default to original
);

has spell_cmd => (
    is      => 'ro',
    isa     => 'Str',
    default => '',                           # default to original
);

has stopwords => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },                   # default to original
);

around add_file => sub {
    my ($orig, $self, $file) = @_;
    my ($set_spell_cmd, $add_stopwords, $stopwords);
    if ($self->spell_cmd) {
        $set_spell_cmd = sprintf "set_spell_cmd('%s');", $self->spell_cmd;
    }

    # automatically add author names to stopwords
    for (@{ $self->zilla->authors }) {
        local $_ = $_;    # we don't want to modify $_ in-place
        s/<.*?>//gxms;
        push @{ $self->stopwords }, /(\w{2,})/gxms;
    }

	if ( $self->zilla->stash_named( 'copyright_holder' ) ) {
		for ( split( ' ', $self->zilla->stash_named( 'copyright_holder' ) ) ) {
			$self->log_debug( $_ );
			push @{ $self->stopwords };
		}
	} else {
		$self->log_debug( 'no copyright_holder found' );
	}

    if (@{ $self->stopwords } > 0) {
        $add_stopwords = 'add_stopwords(<DATA>);';
        $stopwords = join "\n", '__DATA__', @{ $self->stopwords };
    }
    $self->$orig(
        Dist::Zilla::File::InMemory->new(
            {   name    => $file->name,
                content => $self->fill_in_string(
                    $file->content,
                    {   wordlist      => \$self->wordlist,
                        set_spell_cmd => \$set_spell_cmd,
                        add_stopwords => \$add_stopwords,
                        stopwords     => \$stopwords,
                    },
                ),
            }
        ),
    );
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Author tests for POD spelling

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::PodSpelling]

or:

    [Test::PodSpelling]
    wordlist = Pod::Wordlist
    spell_cmd = aspell list
    stopwords = CPAN
    stopwords = github
    stopwords = stopwords
    stopwords = wordlist

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
the following file:

  xt/author/pod-spell.t - a standard Test::Spelling test

=method wordlist

The module name of a word list you wish to use that works with
L<Test::Spelling>.

Defaults to L<Pod::Wordlist::hanekomu>.

=method spell_cmd

If C<spell_cmd> is set then C<set_spell_cmd( your_spell_command );> is
added to the test file to allow for custom spell check programs.

Defaults to nothing.

=method stopwords

If stopwords is set then C<add_stopwords( E<lt>DATAE<gt> )> is added
to the test file and the words are added after the C<__DATA__>
section.

C<stopwords> can appear multiple times, one word per line.

Normally no stopwords are added by default, but author names appearing in
C<dist.ini> are automatically added as stopwords so you don't have to add them
manually just because they might appear in the C<AUTHORS> section of the
generated POD document.

=begin Pod::Coverage

mvp_multivalue_args

=end Pod::Coverage

=cut
__DATA__
___[ xt/author/pod-spell.t ]___
#!perl
# This test is generated by Dist::Zilla::Plugin::Test::PodSpelling

use Test::More;

eval "use {{ $wordlist }}";
plan skip_all => "{{ $wordlist }} required for testing POD spelling"
  if $@;

eval "use Test::Spelling 0.12";
plan skip_all => "Test::Spelling 0.12 required for testing POD spelling"
  if $@;

{{ $set_spell_cmd }}
{{ $add_stopwords }}
all_pod_files_spelling_ok('lib');
{{ $stopwords }}
