use v5.40;
use experimental 'class';

class Minima::Router;

use Carp;
use Path::Tiny;
use Router::Simple;

field $router = Router::Simple->new;
field %special;

method match ($env)
{
    $router->match($env) // $special{not_found};
}

method read_file ($file)
{
    $file = path($file);
    croak "Routes file `$file` does not exist.\n"
        unless -e $file->absolute;

    # Parse routes
    for ($file->lines_utf8) {
        # Skip blank or comment lines
        next if /^\s*#|^\s*$/;

        # Extract data
        my ($method, $pattern, $controller, $action) = split;

        # Fix controller prefix
        $controller =~ s/^:+/Controller::/;

        # Build destination and options
        my %dest = ( controller => $controller, action => $action );
        my %opt;
        $opt{method} = $method unless $method eq '*';

        # Test the nature of the route
        if ($method eq '@') {
            # Special
            $special{$pattern} = \%dest;
        } else {
            # Regular
            $router->connect($pattern, \%dest, \%opt);
        }
    }
}

method _connect
{
    $router->connect(@_);
}

method error_route
{
    $special{server_error}
}
