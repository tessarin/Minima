use v5.40;

package Minima::Setup;

use Minima::App;

sub init ($env)
{
    my $app = Minima::App->new;
    $app->run;
}
