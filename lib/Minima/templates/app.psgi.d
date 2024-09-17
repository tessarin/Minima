use lib 'lib';
@@ IF static
use Plack::Builder;
@@ END
use Minima::Setup;

@@ IF static
my $env = $ENV{PLACK_ENV} // 'unknown';

builder {
    enable_if { $env eq 'development' } "Static",
        path => sub { 1 },
        root => 'static/',
        pass_through => 1,
        ;
    \&Minima::Setup::init;
}
@@ ELSE
\&Minima::Setup::init;
@@ END
