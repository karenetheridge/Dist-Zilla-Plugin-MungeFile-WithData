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

use Module::Metadata;
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

    $file->content(
        $self->fill_in_string(
            $file->content,
            {
                dist => \($self->zilla),
                DATA => \($self->_data_from_file($file)),
            },
        )
    );
}

sub _data_from_file
{
    my ($self, $file) = @_;

    my $pkg = Module::Metadata->new_from_file($file->name)->name;

    # note: DATA is a global, and if code ever tries to read from it more than
    # once, the second time will fail -- if this is a problem, we will need to
    # import Data::Section into the package and then have everything use that
    # instead (and patch to handle reading from other packages), or seek
    # to position 0 and find __DATA__ again -- also see Data::Section::Simple

    require $file->name;
    my $dh = do { no strict 'refs'; \*{"$pkg\::DATA"} };
    # TODO: check defined fileno *$dh ?

    my $data = '';
    while (my $line = <$dh>)
    {
        last if $line =~ /^__END__/;
        $data .= $line;
    }

    return $data;
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    [MungeFile::WithData]
    finder = :MainModule

And during the build, F<lib/My/Module.pm>:

    my @stuff = qw(
        {{ join "    \n",
            map { expensive_build_time_sub($_) }
            split(' ', $DATA)   # awk-style whitespace splitting
        }}
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

=head1 WARNING!

This is not the feature set that is intended to be provided by this plugin.
Use with discretion until the interface and features have stabilized!

=head1 DESCRIPTION

This is a C<FileMunger> plugin for L<Dist::Zilla> that passes the main module
through a L<Text::Template>, with a variable provided that contain the
content from the file's C<__DATA__> section.

L<Text::Template> is used to transform the file by making the C<< $DATA >>
variable available to all code blocks within C<< {{ }} >> sections.

The module being transformed is loaded first, before the template content is
transformed, in order to extract the C<__DATA__> section. While it would seem
that the module will not compile in this state, it is possible to craft the
file content in order to allow the file to parse (e.g. see
L<Acme::CPANAuthors::Nonhuman> version 0.005).

This is a wacky idea though (ether discovered she could be I<clever>! What
fun!) and this will not be a permanent feature of this plugin - in the future
it is intended that the C<__DATA__> section will instead be extracted by
scanning the file for C<< qr/^__DATA__$/ >>.

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
