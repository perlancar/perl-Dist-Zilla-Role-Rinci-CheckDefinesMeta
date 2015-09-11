package Dist::Zilla::Role::Rinci::CheckDefinesMeta;

# DATE
# VERSION

use 5.010001;
use Moose::Role;

sub check_dist_defines_rinci_meta {
    no strict 'refs';

    my $self = shift;

    # cache result
    state $res;
    return $res if defined $res;

    my $files = $self->zilla->find_files(':InstallModules');

    local @INC = ("lib", @INC);
    $res = 0;
    for my $file (@$files) {
        my $name = $file->name;
        $name =~ s!\Alib/!!;
        require $name;
        my $pkg = $name; $pkg =~ s/\.pm\z//; $pkg =~ s!/!::!g;
        if (keys %{"$pkg\::SPEC"}) {
            $res = 1;
            last;
        }
    }

    $res;
}

no Moose::Role;
1;
# ABSTRACT: Role to check if dist defines Rinci metadata

=head1 METHODS

=head2 $obj->check_dist_defines_rinci_meta => bool

Will return true if dist defines Rinci metadata. Currently this is checked via
loading all the module files and checking whether C<%SPEC> in the corresponding
package contains stuffs.

Scripts (and example or shared Perl code) are currently skipped, so if you
define Rinci metadata in those places this routine will not detect them.


=head1 SEE ALSO

L<Rinci>
