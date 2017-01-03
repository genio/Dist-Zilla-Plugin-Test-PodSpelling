use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Path::Tiny;

my $fname  = 'Some';
my $mi     = 'G';
my $lname1 = 'Person';
my $lname2 = 'Thingy';
my $author = "$fname $mi $lname1 - $lname2";

sub get_content {
  my ($args) = @_;

  my $name = 'Test::PodSpelling';
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/foo' },
    {
      add_files => {
        'source/.stopwords' => "foo\nbar\nbaz\n",
        'source/.other_stopwords' => "other\nwords\nhere\n",
        'source/lib/Spell/Checked.pm' => "package Spell::Checked;\n1;\n",
        'source/dist.ini' => dist_ini(
          {
            name => 'Spell-Checked',
            version => 1,
            abstract => 'spelled wrong',
            license => 'Perl_5',
            author => $author,
            copyright_holder => $author,
          },
          [GatherDir =>],
          [$name => $args],
        )
      }
    }
  );

  $tzil->build;
  my $build_dir = path($tzil->tempdir)->child('build');
  my $file = $build_dir->child('xt', 'author', 'pod-spell.t');
  return $file->slurp_utf8;
}

# test with default settings
{
    my $content = get_content({});

    like   $content, qr/foo/xms, 'includes foo';
    like   $content, qr/bar/xms, 'includes bar';
    like   $content, qr/baz/xms, 'includes baz';

    SKIP: {
        skip 'qr//m does not work properly in 5.8.8', 3,
            unless "$]" > '5.010';

        like   $content, qr/^foo$/xms, q[includes foo];
        like   $content, qr/^bar$/xms, q[includes bar];
        like   $content, qr/^baz$/xms, q[includes baz];
    }
}

# test with other file
{
    my $content = get_content({wordfile => '.other_stopwords'});

    unlike   $content, qr/foo  /xms, 'does not include foo';
    unlike   $content, qr/bar  /xms, 'does not include bar';
    unlike   $content, qr/baz  /xms, 'does not include baz';
    like   $content, qr/other/xms, 'includes other';
    like   $content, qr/words/xms, 'includes words';
    like   $content, qr/here /xms, 'includes here';

    SKIP: {
        skip 'qr//m does not work properly in 5.8.8', 3,
            unless "$]" > '5.010';

        unlike   $content, qr/^foo$/xms, q[does not include foo];
        unlike   $content, qr/^bar$/xms, q[does not include bar];
        unlike   $content, qr/^baz$/xms, q[does not include baz];
        like   $content, qr/^other$/xms, q[includes other];
        like   $content, qr/^words$/xms, q[includes words];
        like   $content, qr/^here$/xms,  q[includes here];
    }
}

done_testing;
