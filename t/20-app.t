use v5.40;
use Test2::V0;
use Path::Tiny;
use Data::Dumper;

$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;

use Minima::App;

my $dir = Path::Tiny->tempdir;
chdir $dir;

mkdir 'etc';
my $routes = $dir->child('etc/routes.map');
my $custom_routes = $dir->child('etc/custom.map');

my $env = { PATH_INFO => '/' };
my $app;

# Load routes
like(
    dies { $app = Minima::App->new(environment => $env) },
    qr/routes.*not exist/i,
    'dies for non-existing default routes file'
);

$routes->spew();
ok(
    lives { $app = Minima::App->new(environment => $env) },
    'loads default routes file'
) or note($@);

$custom_routes->spew('* / C a');
my $config = { routes => 'etc/custom.map' };
ok(
    lives {
        $app = Minima::App->new(
            environment => $env,
            configuration => $config,
        )
    },
    'loads custom routes file'
) or note($@);

# Internal _load_class
like(
    dies { $app->_load_class('ThisClassDoesNotExist') },
    qr/could not load/i,
    'dies loading non-existing class'
);

{
    my $simple = $dir->child('Simple.pm');
    my $nested = $dir->child('Nested/Class.pm');
    mkdir 'Nested';
    $simple->spew(1);
    $nested->spew(1);

    local @INC = ( $dir->absolute, @INC );

    ok(
        lives { $app->_load_class('Simple') },
        'loads simple class'
    ) or note($@);

    ok(
        lives { $app->_load_class('Nested::Class') },
        'loads nested class'
    ) or note($@);
}

# Routes properly
my $class = $dir->child('C.pm');
$class->spew(<<~'EOF'
    use v5.40;
    use experimental 'class';
    class C {
        field $environment :param;
        field $app :param;
        field $route :param;
        method a { 'secret' }
        method b { 'error' }
        method d { die '500' }
    }
    EOF
);
{
    local @INC = ( $dir->absolute, @INC );
    local %ENV = %ENV;

    $routes->spew(<<~EOF
        * / C a
        * /d C d
        @ server_error C b
        EOF
    );

    # Normal
    $app = Minima::App->new(
        environment => $env
    );
    my $response = $app->run;
    is( $response, 'secret', 'routes properly' )
        or note('Response dump: ' . Dumper($response));

    # Not found
    $env->{PATH_INFO} = '/c';
    $app = Minima::App->new(
        environment => $env
    );
    $response = $app->run;
    is( ref $response, ref [], 'not found returned proper response' );
    is( $response->[0], 404, 'handles not found' );

    # Force an error page
    $env->{PATH_INFO} = '/d';
    $app = Minima::App->new(
        environment => $env
    );
    $ENV{PLACK_ENV} = 'deployment';
    is( $app->run, 'error', 'handles error properly' );
    $ENV{PLACK_ENV} = 'development';
    like(
        dies { $app->run },
        qr/^500/,
        're-throws error on development'
    );
}

chdir;

done_testing;
