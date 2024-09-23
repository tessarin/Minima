use v5.40;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Minima',
    share_dir => 'share',
    requires => {
        perl => '5.40.0',
    },
    license => 'mit',
);

$build->create_build_script;
