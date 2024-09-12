use v5.40;
use experimental 'class';

class Minima::Controller;

field $env      :param(environment);
field $app      :param;
field $route    :param = {};

method home
{
    [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [ "hello, world\n" ]
    ]
}

method not_found
{
    [
        404,
        [ 'Content-Type' => 'text/plain' ],
        [ "not found\n" ]
    ]
}
