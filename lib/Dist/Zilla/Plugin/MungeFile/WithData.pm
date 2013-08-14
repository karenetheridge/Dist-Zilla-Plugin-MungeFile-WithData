use strict;
use warnings;
package Dist::Zilla::Plugin::MungeFile::WithData;
# ABSTRACT: Modify files in the build, with templates and DATA section

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::FileFinderUser' => { default_finders => [ ] },
);

use namespace::autoclean;

sub munge_files
{
    my $self = shift;
    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file
{
    my ($self, $file) = @_;

    $self->log_debug([ 'MungeWithData updating contents of %s in memory', $file->name ]);

    my $content = $file->content;
    (my $data = $content) =~ s/^.*\n__DATA__\n/\n/s; # for win32
    $data =~ s/\n__END__\n.*$/\n/s;

    $file->content(
        $self->fill_in_string(
            $content,
            {
                dist => \($self->zilla),
                DATA => \$data,
            },
        )
    );
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    [MungeFile::WithData]
    finder = :MainModule

And during the build, F<lib/My/Module.pm>:

    my $DATA;
    my @stuff = qw(# start template...{{
        {{
        $DATA ?
        do {
            join "    \n",
            map { expensive_build_time_sub($_) }
            split(' ', $DATA)   # awk-style whitespace splitting
        }
        : ()
        # end template
        #}}
    );
    __DATA__
    alpha
    beta
    gamma

Is transformed to:

    my @stuff = qw(
        SOMETHING_WITH_ALPHA
        SOMETHING_WITH_BETA
        SOMETHING_WITH_GAMMA
    );

=head1 DESCRIPTION

This is a C<FileMunger> plugin for L<Dist::Zilla> that passes the main module
through a L<Text::Template>, with a variable provided that contain the
content from the file's C<__DATA__> section.

L<Text::Template> is used to transform the file by making the C<< $DATA >>
variable available to all code blocks within C<< {{ }} >> sections.

The data section is extracted by scanning the file for C<< qr/^__DATA__$/ >>,
so this may pose a problem for you if you include this string in a here-doc or
some other construct.  However, this method means we do not have to load the
file before applying the template, which makes it much easier to construct
your templates in F<.pm> files (i.e. not having to put C<{{> after a comment
and inside a C<do> block, as was previously required).

=for Pod::Coverage munge_files munge_file

=head1 OPTIONS

=begin :list

* C<finder>

=for stopwords FileFinder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder> for finding
files to modify.

Other pre-defined finders are listed in
L<FileFinder|Dist::Zilla::Role::FileFinderUser/default_finders>.
You can define your own with the
L<Dist::Zilla::Plugin::FileFinder::ByName|[FileFinder::ByName]> plugin.

The default is C<:MainModule>.

=end :list

=head1 BACKGROUND

This module was originally a part of the L<Acme::CPANAuthors::Nonhuman>
distribution, used to transform a C<DATA> section containing a list of PAUSE
ids to their corresponding names, as well as embedded HTML with everyone's
avatar images.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-MungeFile::WithData>
(or L<bug-Dist-Zilla-Plugin-MungeFile::WithData@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-MungeFile::WithData@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=begin :list

* L<Dist::Zilla::Plugin::Substitute>
* L<Dist::Zilla::Plugin::TemplateFiles>

=end :list

=cut
