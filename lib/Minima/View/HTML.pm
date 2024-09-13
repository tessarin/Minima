use v5.40;
use experimental 'class';

class Minima::View::HTML;

use Carp;
use Path::Tiny;
use Template;

field $app                  :param;
field $directory;
field $template;

field %settings = (
    block_indexing => 1,    # block robots with a <meta>
    name_as_class => 1,     # include template name in @classes
);

field %content = (
    title => undef,
    description => undef,
    header_scripts => [],   # scripts to be loaded in <head>
    header_css => [],       # CSS to be loaded in <head>
    pre => [],              # global partials before a template
    post => [],             # global partials after a template
    pre_body => [],         # used right before the opening of <body>
    scripts => [],          # scripts to be embedded directly in <body>
    classes => [],          # classes added to <main>
);

ADJUST {
    my $config = $app->config;

    $content{title} = $config->{default_title} // '';
    $settings{block_indexing} = $config->{block_indexing} // 1;
}

method set_title ($t, $d = undef)
{
    $content{title} = $t;
    $content{description} = $d;
}

method set_compound_title ($t, $d = undef)
{
    $self->set_title(
        ( $content{title} ? "$content{title} • $t" : $t ),
        $d
    );
}

method set_directory      ($d) { $directory = path($d)->absolute }
method set_template       ($t) { $template = $t }

method set_block_indexing ($n = 1) { $settings{block_indexing} = $n }
method set_name_as_class  ($n = 1) { $settings{name_as_class} = $n }

method add_header_script  ($s) { push @{$content{header_scripts}}, $s }
method add_header_css     ($c) { push @{$content{header_css}}, $c }
method add_pre            ($p) { push @{$content{pre}}, $p }
method add_post           ($p) { push @{$content{post}}, $p }
method add_pre_body       ($p) { push @{$content{pre_body}}, $p }
method add_script         ($s) { push @{$content{scripts}}, $s }
method add_class          ($c) { push @{$content{classes}}, $c }

method render ($data)
{
    croak "No template set." unless $template;
    croak "No template directory set." unless $directory;

    # Build vars to send to template
    my %vars = ( %content, settings => \%settings );
    $data->{view} = \%vars;

    # Format CSS classes
    my $classes = $content{classes};
    if ($settings{name_as_class}) {
        my $clean_name = $content{title};
        $clean_name =~ tr/./-/;
        push @$classes, $clean_name;
    }
    $vars{classes} = "@$classes";

    # Render
    my $tt = Template->new(
        INCLUDE_PATH => $directory,
        # XXX: Encoding and debug
    );

    my ( $body, $r );

    for my $t (@{ $content{pre} }, $template, @{ $content{post} }) {
        $r = $tt->process($t, $data, \$body);
        croak "Failed to load template `$t`: ", $tt->error, "\n" unless $r;
    }

    $body;
}
