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

    $res = 0;

    {
        my $files = $self->zilla->find_files(':InstallModules');
        local @INC = ("lib", @INC);
        for my $file (@$files) {
            my $name = $file->name;
            next if $name =~ /\.pod\z/i;
            $name =~ s!\Alib/!!;
            require $name;
            my $pkg = $name; $pkg =~ s/\.pm\z//; $pkg =~ s!/!::!g;
            if (keys %{"$pkg\::SPEC"}) {
                $self->log_debug(["Found that %%%s\::SPEC contains stuffs",
                                  $pkg]);
                $res = 1;
                goto DONE;
            }
        }
    }

    {
        require File::Temp;
        require PPI::Document;
        my $files = $self->zilla->find_files(':ExecFiles');
        for my $file (@$files) {
            my $path;
            if ($file->isa("Dist::Zilla::File::OnDisk")) {
                $path = $file->name;
            } else {
                my ($temp_fh, $temp_path) = tempfile();
                print $temp_fh $file->content;
                $path = $temp_path;
            }
            my $doc = PPI::Document->new($path);
            for my $node ($doc->children) {
                next unless $node->isa("PPI::Statement");
                my @chld = $node->children;
                next unless @chld;
                next unless $chld[0]->isa("PPI::Token::Symbol") &&
                    $chld[0]->content =~ /\A\$(main::)?SPEC\z/;
                my $i = 1;
                while ($i < @chld) {
                    last unless $chld[$i]->isa("PPI::Token::Whitespace");
                    $i++;
                }
                next unless $i < @chld;
                next unless $chld[$i]->isa("PPI::Structure::Subscript") &&
                    $chld[$i]->content =~ /\A\{/;
                $i++;
                while ($i < @chld) {
                    last unless $chld[$i]->isa("PPI::Token::Whitespace");
                    $i++;
                }
                next unless $i < @chld;
                next unless $chld[$i]->isa("PPI::Token::Operator") &&
                    $chld[$i]->content eq '=';
                $self->log_debug(
                    ['Found that %s contains assignment to $SPEC{...}',
                     $file->name]);
                $res = 1;
                goto DONE;
            }
        }
    }

  DONE:
    $res;
}

no Moose::Role;
1;
# ABSTRACT: Role to check if dist defines Rinci metadata

=head1 METHODS

=head2 $obj->check_dist_defines_rinci_meta => bool

Will return true if dist defines Rinci metadata. Currently this is done via the
following: 1) load all the module files and check whether C<%SPEC> in the
corresponding package contains stuffs; 2) analyze all the scripts using L<PPI>
and try to find any assignment like C<< $SPEC{something} = { ... } >> (this
might miss some stuffs).


=head1 SEE ALSO

L<Rinci>
