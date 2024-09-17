use v5.40;

package Minima::Project;

use FindBin;
use Path::Tiny;
use Template;

our $tdir = path(__FILE__)->parent->child('/templates')->absolute;

sub create ($dir)
{
    my $project   = path($dir // '.')->absolute;

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
    for my ($file, $content) (%{ get_templates() }) {
        my $dest = path($file);
        my $dir = $dest->parent;

        $dir->mkdir unless $dir->is_dir;
        $dest->spew_utf8($content);
    }
}

sub get_templates
{
    my %files;

    foreach (glob "$tdir/*.[sd]") {
        my $content = path($_)->slurp_utf8;
        $_ = path($_)->basename;
        tr|-|/|;
        tr|+|.|;
        if (/\.d/) {
            # TODO: Process dynamic templates
        }
        s/\.\w$//;
        $files{$_} = $content;
    }

    \%files;
}

1;
