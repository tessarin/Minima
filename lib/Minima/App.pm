use v5.40;
use experimental 'class';

class Minima::App;

use Carp;
use Minima::Router;

field $env      :param(environment);
field $config   :param(configuration) :reader = {};

field $router = Minima::Router->new;

ADJUST {
    $self->_load_routes;
}

method run
{
    my $m = $router->match($env);

    return $self->not_found unless $m;

    my $class  = $m->{controller};
    my $method = $m->{action};

    $self->_load_class($class);

    my $controller = $class->new;

    $controller->$method;
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
