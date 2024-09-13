use v5.40;
use experimental 'class';

class Minima::View;

use Carp;

method render
{
    carp "Base view render called.";
    "hello, world\n";
}
