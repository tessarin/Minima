use v5.40;
use experimental 'class';

class Minima::App;

method run
{
    [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [ "hello, world\n" ]
    ]
}
