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
