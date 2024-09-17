use v5.40;
use experimental 'class';

class Minima::View::HTML;

use Carp;
use Path::Tiny;
use Template;
use Template::Constants qw/ :debug /;

field $app                  :param;
field $directory            = 'templates';
field $template;

field %settings = (
    block_indexing => 1,    # block robots with a <meta>
    name_as_class => 1,     # include template name in @classes
    theme_color => '',      # hex color for the <meta theme-color>
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
    $settings{theme_color} = $config->{theme_color} // '';
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

method set_directory ($d)
{
    $directory = path($d)->absolute
}

method set_template ($t)
{
    $template = _ext($t);
}

method set_block_indexing ($n = 1) { $settings{block_indexing} = $n }
method set_name_as_class  ($n = 1) { $settings{name_as_class} = $n }

method add_header_script  ($s) { push @{$content{header_scripts}}, $s }
method add_header_css     ($c) { push @{$content{header_css}}, $c }
method add_pre            ($p) { push @{$content{pre}}, _ext($p) }
method add_post           ($p) { push @{$content{post}}, _ext($p) }
method add_pre_body       ($p) { push @{$content{pre_body}}, $p }
method add_script         ($s) { push @{$content{scripts}}, $s }
method add_class          ($c) { push @{$content{classes}}, $c }

method render ($data = {})
{
    croak "No template set." unless $template;

    # Build vars to send to template
    my %vars = ( %content, settings => \%settings );
    $data->{view} = \%vars;

    # Format CSS classes
    my @classes = @{ $content{classes} };
    if ($settings{name_as_class}) {
        my $clean_name = $template;
        $clean_name =~ s/\.\w+$//;
        $clean_name =~ tr/./-/;
        push @classes, $clean_name;
    }
    $vars{classes} = "@classes";

    # If any var is undef, replace with empty string
    $vars{$_} //= '' for keys %vars;

    # Setup Template Toolkit:
    # Create a default and overwrite with user configuration.
    my %tt_default = (
        INCLUDE_PATH => $directory,
        OUTLINE_TAG => '%%',
        ANYCASE => 1,
    );
    if ($app->development) {
        $tt_default{DEBUG} = DEBUG_UNDEF;
    }
    my $tt_app_config = $app->config->{tt} // {};
    my %tt_config = ( %tt_default, %$tt_app_config );
    my $tt = Template->new(\%tt_config);

    # Render
    my ( $body, $r );

    for my $t (@{ $content{pre} }, $template, @{ $content{post} }) {
        $r = $tt->process($t, $data, \$body);
        croak "Failed to load template `$t` (at `$directory`): ",
              $tt->error, "\n" unless $r;
    }

    $body;
}

sub _ext ($file)
{
    $file = "$file.tt" unless $file =~ /\.\w+$/;
}
