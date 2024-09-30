use v5.40;
use Test2::V0;

use Minima::App;
use Minima::Controller;

my $app = Minima::App->new;
my $c = Minima::Controller->new(
    app => $app,
    route => { },
);

my $response = $c->hello;
is( ref $response, ref [], 'returns array ref' );
is( scalar @$response, 3, 'returns valid array ref' );
is( $response->[0], 200, 'returns valid response code' );

done_testing;
