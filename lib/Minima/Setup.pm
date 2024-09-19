use v5.40;

package Minima::Setup;

use Carp;
use Minima::App;
use Path::Tiny;

our $config = {};

sub import
{
    shift; # discard package name
    my $file = shift if @_;
    my $default_config = './etc/config.pl';

    if ($file) {
        my $file_abs = path($file)->absolute;

        croak "Config file `$file` does not exist.\n"
            unless -e $file_abs;

        $config = do $file_abs;
        croak "Failed to parse config file `$file`: $@\n" if $@;

    } elsif (-e $default_config) {
        $config = do $default_config;
        croak "Failed to parse default config file `$default_config`: "
            . "$@\n" if $@;
    }
    croak "Config is not a hash reference.\n"
        unless ref $config eq ref {};
}

sub init ($env)
{
    my $app = Minima::App->new(
        environment => $env,
        configuration => $config,
    );
    $app->run;
}

__END__

=head1 NAME

Minima::Setup - Setup a Minima web application

=head1 SYNOPSIS

    # app.psgi
    use Minima::Setup 'config.pl';
    \&Minima::Setup::init;

=head1 DESCRIPTION

This package is dedicated to the initial setup of a web application
using L<Minima>. It provides the L<C<init>|/init> subroutine which runs
the app and can be passed (as a reference) as the starting subroutine of
a PSGI application.

=head1 CONFIG FILE

A single argument may be optionally passed when C<use>-ing this module,
representing the configuration file. Minima::Setup will attempt to read
this file and use it to initialize L<Minima::App>.

By default, the configuration file is assumed to be F<etc/config.pl>. If
this file exists and no other location is provided, it will be used. If
nothing was passed and no file exists at the default location, the app
will be loaded with an empty configuration hash.

=head1 SUBROUTINES

=head2 init

    sub init ($env)

Receives the Plack environment and creates and runs a L<Minima::App>
object. A reference to this subroutine can be passed as the starting
point of the PSGI application.

=head1 SEE ALSO

L<Minima>, L<Plack>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
