# NAME

Dist::Zilla::Plugin::MungeFile::WithData - Modify files in the build, with templates and DATA section

# VERSION

version 0.001

# SYNOPSIS

In your `dist.ini`:

    [MungeFile::WithData]
    finder = :MainModule

And during the build, `lib/My/Module.pm`:

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

# DESCRIPTION

This is a `FileMunger` plugin for [Dist::Zilla](http://search.cpan.org/perldoc?Dist::Zilla) that passes the main module
through a [Text::Template](http://search.cpan.org/perldoc?Text::Template), with a variable provided that contain the
content from the file's `__DATA__` section.

[Text::Template](http://search.cpan.org/perldoc?Text::Template) is used to transform the file by making the `$DATA`
variable available to all code blocks within `{{ }}` sections.

The module being transformed is loaded first, before the template content is
transformed, in order to extract the `__DATA__` section. While it would seem
that the module will not compile in this state, it is possible to craft the
file content in order to allow the file to parse (e.g. see
[Acme::CPANAuthors::Nonhuman](http://search.cpan.org/perldoc?Acme::CPANAuthors::Nonhuman) version 0.005).

This is a wacky idea though (ether discovered she could be _clever_! What
fun!) and this will not be a permanent feature of this plugin - in the future
it is intended that the `__DATA__` section will instead be extracted by
scanning the file for `qr/^__DATA__$/`.

# WARNING!

This is not the feature set that is intended to be provided by this plugin.
Use with discretion until the interface and features have stabilized!

# OPTIONS

- `finder`

    This is the name of a [FileFinder](http://search.cpan.org/perldoc?Dist::Zilla::Role::FileFinder) for finding
    files to modify.

    Other pre-defined finders are listed in
    [FileFinder](http://search.cpan.org/perldoc?Dist::Zilla::Role::FileFinderUser#default\_finders).
    You can define your own with the
    [Dist::Zilla::Plugin::FileFinder::ByName](http://search.cpan.org/perldoc?\[FileFinder::ByName\]) plugin.

    The default is `:MainModule`.

# BACKGROUND

This module was originally a part of the [Acme::CPANAuthors::Nonhuman](http://search.cpan.org/perldoc?Acme::CPANAuthors::Nonhuman)
distribution, used to transform a `DATA` section containing a list of PAUSE
ids to their corresponding names, as well as embedded HTML with everyone's
avatar images.

# SUPPORT

Bugs may be submitted through [the RT bug tracker](https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-MungeFile::WithData)
(or [bug-Dist-Zilla-Plugin-MungeFile::WithData@rt.cpan.org](mailto:bug-Dist-Zilla-Plugin-MungeFile::WithData@rt.cpan.org)).
I am also usually active on irc, as 'ether' at `irc.perl.org`.

# SEE ALSO

- [Dist::Zilla::Plugin::Substitute](http://search.cpan.org/perldoc?Dist::Zilla::Plugin::Substitute)
- [Dist::Zilla::Plugin::TemplateFiles](http://search.cpan.org/perldoc?Dist::Zilla::Plugin::TemplateFiles)

# AUTHOR

Karen Etheridge <ether@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
