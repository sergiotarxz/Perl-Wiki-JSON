# NAME

Wiki::JSON - Parse wiki-like articles to a data-structure transformable to JSON.

# SYNOPSIS

    use Wiki::JSON;

    my $structure = Wiki::JSON->new->parse(<<'EOF');
    = This is a wiki title
    '''This is bold'''
    ''This is italic''
    '''''This is bold and italic'''''
    == This is a smaller title, the user can use no more than 6 equal signs
    <nowiki>''This is printed without expanding the special characters</nowiki>
    * This
    * Is
    * A
    * Bullet
    * Point
    * List
    {{foo|Templates are generated|with their arguments}}
    {{stub|This is under heavy development}}
    The parser has some quirks == This will generate a title ==
    ''' == '' Unterminated syntaxes will still be parsed until the end of file
    This is a link to a wiki article: [[Cool Article]]
    This is a link to a wiki article with an alias: [[Cool Article|cool article]]
    EOF

# DESCRIPTION

A parser for a subset of a mediawiki-like syntax, quirks include some
supposedly inline elements are parsed multi-line like headers, templates\*,
italic and bolds.

# DESCRIPTION

A parser for a subset of a mediawiki-like syntax, quirks include some
supposedly inline elements are parsed multi-line like headers, templates\*,
italic and bolds.

Lists are only one level and not everything in mediawiki is supported by the
moment.

## INSTALLING

    cpanm https://github.com/sergiotarxz/Perl-Wiki-JSON.git

## USING AS A COMMAND

    wiki2json file.wiki > output.json

# INSTANCE\_METHODS

## new

    my $wiki_parser = Wiki::JSON->new;

# METHODS

## parse

    my $structure = $wiki_parser->parse($wiki_string);

Parses the wiki format into a serializable to JSON or YAML Perl data structure.

# BUGS

The author thinks it is possible the parser hanging forever, use it in
a subprocess the program can kill if it takes too long.

The developer can use fork, waitpid, pipe, and non-blocking IO for that.

# LEGAL

Copyright ©Sergiotarxz (2025)

You can use this software under the terms of the GPLv3 license or a new later
version provided by the FSF or the GNU project.

# SEE ALSO

Look what is supported and how in the tests: [https://github.com/sergiotarxz/Perl-Wiki-JSON/tree/main/t](https://github.com/sergiotarxz/Perl-Wiki-JSON/tree/main/t)
