use v5.40;
use experimental 'class';

class Minima::Controller;

method home
{
    [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [ "hello, world\n" ]
    ]
}
