use v5.40;
use experimental 'class';

class Minima::App;

use Carp;
use Minima::Router;

use constant DEFAULT_VERSION => 'prototype';

field $env      :param(environment)   :reader = undef;
field $config   :param(configuration) :reader = {};

field $router = Minima::Router->new;

ADJUST {
    $self->_load_routes;
    $self->_set_version;
}

method development
{
    return 1 if not defined $ENV{PLACK_ENV};

    $ENV{PLACK_ENV} eq 'development'
}

method run
{
    croak "Can't run without an environment.\n" unless defined $env;

    my $m = $router->match($env);

    return $self->_not_found unless $m;

    my $class  = $m->{controller};
    my $method = $m->{action};

    $self->_load_class($class);

    my $controller = $class->new(
        environment => $env,
        app => $self,
        route => $m,
    );

    try {
        $controller->$method;
    } catch ($e) {
        my $err = $router->error_route;
        # Something failed. If we're in production
        # and there is a server_error route, try it.
        if (!$self->development && $err) {
            $class  = $err->{controller};
            $method = $err->{action};
            $self->_load_class($class);
            $controller = $class->new(
                environment => $env,
                app => $self,
                route => $err,
            );
            $controller->$method($e);
        } else {
            # Nothing can be done, re-throw
            die $e;
        }
    }
}

method _not_found
{
    [
        404,
        [ 'Content-Type' => 'text/plain' ],
        [ "not found\n" ]
    ]
}

method _load_routes
{
    my $file = $config->{routes};
    unless (defined $file) {
        # No file passed. Attempt the default route.
        $file = './etc/routes.map';
        # If it does not exist, setup a basic route
        # for the default controller only.
        unless (-e $file) {
            $router->_connect(
                '/',
                {
                    controller => 'Minima::Controller',
                    action => 'hello',
                },
            );
            return;
        }
    }
    $router->read_file($file);
}

method _load_class ($class)
{
    try {
        my $file = $class;
        $file =~ s|::|/|g;
        require "$file.pm";
    } catch ($e) {
        croak "Could not load `$class`: $e\n";
    }
}

method _set_version
{
    return if defined $config->{VERSION};

    if (defined $config->{version_from}) {
        my $class = $config->{version_from};
        try {
            $self->_load_class($class);
        } catch ($e) {
            croak "Failed to load version from class.\n$e\n";
        }
        $config->{VERSION} = $class->VERSION // DEFAULT_VERSION;
    } else {
        $config->{VERSION} = DEFAULT_VERSION;
    }
}

__END__

=head1 NAME

Minima::App - Application class for Minima

=head1 SYNOPSIS

    use Minima::App;

    my $app = Minima::App->new(
        environment => $env,
        configuration => { },
    );
    $app->run;

=head1 DESCRIPTION

Minima::App is the core of a Minima web application. It handles starting
the app, connecting to the router, and dispatching route matches. For
more details on this process, see the L<C<run>|/run> method.

Two essential parts of an app are the routes file and configuration
hash.

The routes file describes the application's routes. Minima::App checks
for the existence of this file and passes it to the router, which
handles reading and processing the routes. For more on how to configure
and specify the location of the routes file, see the
L<C<routes>|/routes> configuration key and L<Minima::Router>.

The configuration hash is central to many operations. This hash is
usually loaded from a file, though it can be passed directly to the
L<C<new>|/new> method. Tipically, this is handled by L<Minima::Setup>.

A reference for the configuration keys used by Minima::App is provided
below. Other modules may also utilize the configuration hash, so refer
to their documentation for module-specific details.

=head2 Configuration

=over 4

=item C<routes>

The location of the routes file. If not specified, it defaults to
F<etc/routes.map>. If no file is found at that location and this key
isn't provided, the app will load a blank state, where it returns a 200
response for the root path and a 404 for any other route.

=item C<VERSION>

The current application version. Instead of passing it directly, you
can use the L<C<version_from>> key to auto-populate this. If neither
C<VERSION> not C<version_from> are provided, it defaults to
C<'prototype'>.

=item C<version_from>

Name of a class from which to extract and set C<VERSION>. Only used if
C<VERSION> wasn't given explicitly.

=back

=head1 METHODS

=head2 new

    method new (environment = undef, configuration = {})

Instantiates the app with the provided Plack environment and
configuration hash. Both parameters are optional. Configuration keys
used by Minima::App are described under L</Configuration>.

=head2 run

    method run ()

Runs the application by querying the router for a match to C<PATH_INFO>
(the URL in the environment hash) and dispatching it.

If the controller-action call fails, Minima::App checks for the
existence of an error route. If the app is I<not in development mode>
and the error route is set, it is called to handle the exception,
with the error message passed as an argument.

If no error route is set, the app dies, passing the exception forward
to be handled by any other middleware.

=head2 development

    method development ()

Utility method that returns true if C<$ENV{PLACK_ENV}> is set to
C<development> or if it is unset. Returns false otherwise.

=head1 ATTRIBUTES

The attributes below are accessible through reader methods.

=over 4

=item C<config>

Returns the configuration hash.

=item C<env>

Returns the environment hash.

=back

=head1 SEE ALSO

L<Minima>, L<Minima::Setup>, L<Minima::Router>, L<perlclass>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
