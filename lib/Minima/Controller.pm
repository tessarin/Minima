use v5.40;
use experimental 'class';

class Minima::Controller;

use Plack::Request;
use Plack::Response;

field $env      :param(environment);
field $app      :param;
field $route    :param = {};

field $request;
field $response;
field $params;

ADJUST {
    $request  = Plack::Request->new($env);
    $response = Plack::Response->new(200);
    $response->content_type('text/plain; charset=utf-8');

    $params = $request->parameters;
}

method home
{
    $response->body("hello, world\n");
    $response->finalize;
}

method not_found
{
    $response->code(404);
    $response->body("not found\n");
    $response->finalize;
}
