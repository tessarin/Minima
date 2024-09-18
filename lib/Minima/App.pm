use v5.40;
use experimental 'class';

class Minima::App 0.001000;

use Carp;
use Minima::Router;

field $env      :param(environment);
field $config   :param(configuration) :reader = {};

field $router = Minima::Router->new;

ADJUST {
    $self->_load_routes;
}

method development
{
    return 1 if not defined $ENV{PLACK_ENV};

    $ENV{PLACK_ENV} eq 'development'
}

method run
{
    my $m = $router->match($env);

    return $self->not_found unless $m;

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

method not_found
{
    [
        404,
        [ 'Content-Type' => 'text/plain' ],
        [ "not found\n" ]
    ]
}

method _load_routes
{
    my $file = $config->{routes} // './etc/routes.map';
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
