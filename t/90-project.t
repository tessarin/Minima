use v5.40;
use Test2::V0;
use Path::Tiny;

use Minima::Project;

my $dir = Path::Tiny->tempdir;
chdir $dir;

ok(
    lives { Minima::Project::create($dir) },
    'lives on empty directory'
);

like(
    dies { Minima::Project::create($dir) },
    qr/must be empty/,
    'dies for non-empty directory'
);

like(
    dies { Minima::Project::create($dir->child('app.psgi')) },
    qr/must be a directory/,
    'dies for file passed as directory'
);

chdir;

done_testing;
