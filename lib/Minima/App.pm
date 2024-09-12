use v5.40;
use experimental 'class';

class Minima::App;

field $env      :param(environment);
field $config   :param(configuration) :reader = {};

method run
{
    [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [ "hello, world\n" ]
    ]
}
