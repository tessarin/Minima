use v5.40;

package Minima::Project;

use FindBin;
use Path::Tiny;
use Template;

our $tdir = path(__FILE__)->parent->child('/templates')->absolute;
our $verbose = 0;

sub create ($dir, $user_config = {})
{
    my $project = path($dir // '.')->absolute;
    my %config = (
        'static' => 1,
        'verbose' => 0,
        %$user_config
    );
    $verbose = $config{verbose};

    # Test if directory can be used
    if ($project->exists) {
        die "Project destination must be a directory\n"
            unless $project->is_dir;
        die "Project destination must be empty.\n"
            if $project->children;
    } else {
        $project->mkdir;
    }

    chdir $project;

    # Create files
    for my ($file, $content) (get_templates(\%config)) {
        my $dest = path($file);
        my $dir = $dest->parent;

        unless ($dir->is_dir) {
            _info("mkdir $dir");
            $dir->mkdir;
        }
        if ($content) {
            _info(" spew $dest");
            $dest->spew_utf8($content);
        }
    }
}

sub get_templates ($config)
{
    my %files;
    use Template::Constants qw/ :debug /;
    my $tt = Template->new(
        INCLUDE_PATH => $tdir,
        OUTLINE_TAG => '@@',
        TAG_STYLE => 'star',
    );

    foreach (glob "$tdir/*.[sd]") {
        my $content = path($_)->slurp_utf8;
        $_ = path($_)->basename;
        tr|-|/|;
        tr|+|.|;
        if (/\.d/) {
            # Process .d(ynamic) template
            my $template = $content;
            my $processed;
            $tt->process(\$template, $config, \$processed);
            $content = $processed;
        }
        s/\.\w$//;
        $files{$_} = $content;
    }

    map { $_, $files{$_} } sort keys %files;
}

sub _info ($m)
{
    say $m if ($verbose);
}

1;
