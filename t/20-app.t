use v5.40;
use Test2::V0;
use Path::Tiny;
use Data::Dumper;

$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;

use Minima::App;

# Setup in temporary directory
my $dir = Path::Tiny->tempdir;
chdir $dir;
mkdir 'etc';

# Dummy controller
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

my $env = { PATH_INFO => '/' };

# Load routes
{
    my $app;

    # totally empty, no default and no custom
    ok(
        lives { $app = Minima::App->new(environment => $env) },
        'runs without routes file'
    );

    my $response = $app->run;
    ok(
        ( ref $response eq ref [] and $response->[0] == 200 ),
        'routes root without a routes file'
    );

    $app = Minima::App->new(
        environment => { PATH_INFO => '/ThisURIDoesNotExist' }
    );
    $response = $app->run;
    ok(
        ( ref $response eq ref [] and $response->[0] == 404 ),
        'routes a bad URI without a routes file',
    );

    # pass a file that does not exist
    like(
        dies {
            $app = Minima::App->new(
                environment => $env,
                configuration => { routes => 'ThisFileDoesNotExist' }
            )
        },
        qr/routes.*not exist/i,
        'dies for non-existing routes file'
    );

    # create one at the default location
    my $routes = $dir->child('etc/routes.map');
    $routes->spew();
    ok(
        lives { $app = Minima::App->new(environment => $env) },
        'loads default routes file'
    ) or note($@);
    $routes->remove;

    # custom location
    my $custom_routes = $dir->child('etc/custom.map');
    $custom_routes->spew(); # etc/custom.map
    my $config = { routes => 'etc/custom.map' };
    ok(
        lives {
            $app = Minima::App->new(
                environment => $env,
                configuration => $config
            )
        },
        'loads custom routes file'
    ) or note($@);
    $custom_routes->remove;
}

# Internal _load_class
{
    my $app = Minima::App->new(environment => $env);

    like(
        dies { $app->_load_class('ThisClassDoesNotExist') },
        qr/could not load/i,
        'dies loading non-existing class'
    );

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

# Internal _set_version
{
    # sets the default version
    my $app = Minima::App->new(
        environment => {},
    );

    is(
        $app->config->{VERSION},
        Minima::App::DEFAULT_VERSION,
        'sets a default version'
    );

    # respects a manually set version
    $app = Minima::App->new(
        environment => {},
        configuration => { VERSION => 'SecretVersion' }
    );

    is(
        $app->config->{VERSION},
        'SecretVersion',
        'respects a manually set version'
    );

    # recognizes from class
    my $class = $dir->child('V.pm');
    $class->spew(<<~'EOF'
        use v5.40;
        use experimental 'class';
        class V 1.234567 { }
        EOF
    );
    local @INC = ( $dir->absolute, @INC );
    $app = Minima::App->new(
        environment => {},
        configuration => { version_from => 'V' }
    );

    is(
        $app->config->{VERSION},
        '1.234567',
        'recognizes version from class'
    );

    # dies for bad class passed
    like(
        dies {
            $app = Minima::App->new(
                environment => {},
                configuration => { version_from => 'W' }
            )
        },
        qr/failed.*version/i,
        'dies for unreadable class to extract version'
    );

    # sets a default for class without version
    my $new_class = $dir->child('X.pm');
    $new_class->spew(<<~'EOF'
        use v5.40;
        use experimental 'class';
        class X { }
        EOF
    );
    $app = Minima::App->new(
        environment => {},
        configuration => { version_from => 'X' }
    );

    is(
        $app->config->{VERSION},
        Minima::App::DEFAULT_VERSION,
        'sets default for class without version'
    );
}

# Routes properly
{
    local @INC = ( $dir->absolute, @INC );
    local %ENV = %ENV;
    my $app;

    my $routes = $dir->child('etc/routes.map');
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
