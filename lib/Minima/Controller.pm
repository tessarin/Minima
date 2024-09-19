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

method hello
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

__END__

=head1 NAME

Minima::Controller - Base class for controllers used with Minima

=head1 SYNOPSIS

    use Minima::Controller;

    my $controller = Minima::Controller->new(
        environment => $env, # Plack $env
        app => $app,         # Minima::App
        route => $match,     # a match returned by Minima::Router
    );
    $controller->hello;

=head1 DESCRIPTION

Serving as a base class to controllers used with L<Minima>, this class
provides the basic infrastructure for any type of controller. It is
built around L<Plack::Request> and L<Plack::Response> objects, allowing
subclasses to interactly directly with Plack.

Minima::Controller also keeps references to the L<Minima::App> and Plack
environment. Additionally, it retains data received from the router,
making it readily available to controllers.

This base class is not connected to any view, which is left to methods
or subclasses. However, it sets a default C<Content-Type> header for the
response as C<'text/plain; charset=utf-8'>.

=head1 METHODS

=head2 new

    method new (app, environment, route = {})

Instantiates a controller with the given C<$app> reference, Plack
environment and optionally the hash reference returned by the router.
If this hash reference contains data extracted from the URI by
L<Minima::Router>, then this data will be made available to the
controller through the L<C<route|/route> field.

=head2 redirect

    method redirect ($url, $code = 302)

Utility method to set the redirect header to the given URL and code
(defaults to 302, a temporary redirect) and finalize the response.

Use with C<return> inside other controller methods to shortcut:

    # someone shouldn't be here
    return $self->redirect('/login');
    # continue for logged in users

=head2 render

    method render ($view, $data = {})

Utility method to call C<render> on the passed view, together with
optional data, and save to the response body. Afterward, it returns the
finalized response.

=head1 EXTRAS

=head2 hello, not_found

Methods used to emit a minimal C<hello, world> or not found response.

=head2 print_env

Returns a plain text printout of the current Plack environment.

=head1 ATTRIBUTES

All attributes below are accessible through reader methods.

=over 4

=item C<env>

Plack environment.

=item C<app>

Reference to a L<Minima::App>.

=item C<route>

Hash reference returned by the router.

=item C<request>

Internal L<Plack::Request>

=item C<response>

Internal L<Plack::Response>

=item C<params>

A shortcut for C<$request-E<gt>parameters>.

=back

=head1 SEE ALSO

L<Minima>, L<Minima::App>, L<Minima::Router>, L<Minima::View>,
L<Plack::Request>, L<Plack::Response>, L<perlclass>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
