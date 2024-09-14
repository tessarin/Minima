use v5.40;
use experimental 'class';

class Minima::Controller;

use Plack::Request;
use Plack::Response;

field $env      :param(environment) :reader;
field $app      :param :reader;
field $route    :param :reader = {};

field $request  :reader;
field $response :reader;
field $params   :reader;

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

method redirect ($url, $code = 302)
{
    $response->redirect($url, $code);
    $response->finalize;
}

method render ($v, $data = {})
{
    $response->body($v->render($data));
    $response->finalize;
}

method print_env
{
    return $self->redirect('/') unless $app->development;

    my $max = 0;
    for (map { length } keys %$env) {
        $max = $_ if $_ > $max;
    }
    $response->body(
        map {
            sprintf "%*s => %s\n", -$max, $_, $env->{$_}
        } sort keys %$env
    );
    $response->finalize;
}
