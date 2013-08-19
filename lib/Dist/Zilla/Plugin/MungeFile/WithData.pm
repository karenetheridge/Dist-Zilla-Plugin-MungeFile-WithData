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
use MooseX::SlurpyConstructor;
use List::Util 'first';
use namespace::autoclean;

sub mvp_multivalue_args { qw(files) }
sub mvp_aliases { { _file => 'files' } }

has files => (
    isa  => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [] },
    traits => ['Array'],
    handles => { files => 'elements' },
);

has _extra_args => (
    isa => 'HashRef[Str]',
    init_arg => undef,
    lazy => 1,
    default => sub { {} },
    traits => ['Hash'],
    handles => { _extra_args => 'elements' },
    slurpy => 1,
);

sub munge_files
{
    my $self = shift;

    my @files = map {
        my $filename = $_;
        my $file = first { $_->name eq $filename } @{ $self->zilla->files };
        defined $file ? $file : ()
    } $self->files;

    $self->munge_file($_) for @files, @{ $self->found_files };
}

sub munge_file
{
    my ($self, $file) = @_;

    $self->log_debug([ 'MungeWithData updating contents of %s in memory', $file->name ]);

    my $content = $file->content;

    my $data;
    if ($content =~ m/\n__DATA__\n/sp)
    {
        $data = ${^POSTMATCH};
        $data =~ s/\n__END__\n.*$/\n/s;
    }

    $file->content(
        $self->fill_in_string(
            $content,
            {
                $self->_extra_args,
                dist => \($self->zilla),
                plugin => \($self),
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
    file = lib/My/Module.pm
    house = maison

And during the build, F<lib/My/Module.pm>:

    my @stuff = qw(
        {{
            join "    \n",
            map { expensive_build_time_sub($_) }
            split(' ', $DATA)   # awk-style whitespace splitting
        }}
    );
    my ${{ $house }} = 'my castle';
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
    my $maison = 'my castle';

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

=for Pod::Coverage munge_files munge_file mvp_aliases

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

=item * C<file>

Indicates the filename in the dist to be operated upon; this file can exist on
disk, or have been generated by some other plugin.  Can be included more than once.

At least one of the C<finder> or C<file> options is required.

=item * C<arbitrary option>

All other keys/values provided will be passed to the template as is.

=end :list

=head1 BACKGROUND

=for stopwords syntactual

This module was originally a part of the L<Acme::CPANAuthors::Nonhuman>
distribution, used to transform a C<DATA> section containing a list of PAUSE
ids to their corresponding names, as well as embedded HTML with everyone's
avatar images.  It used to only work on F<.pm> files, by first loading the
module and then reading from a filehandle created from C<< \*{"$pkg\::DATA"} >>.
This also required the file to jump through some convoluted syntactual hoops
to ensure that the file was still compilable B<before> the template was run.
(Check it out and roll your eyes:
L<https://github.com/karenetheridge/Acme-CPANAuthors-Nonhuman/blob/v0.005/lib/Acme/CPANAuthors/Nonhuman.pm#L18>)

Now that we support munging all file types, we are forced to parse the file
more dumbly (by scanning for C<qr/^__DATA__/>), which also removes the need
for these silly syntax games. The moral of the story is that simple code
usually B<is> better!

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
