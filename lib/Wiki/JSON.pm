package Wiki::JSON;

use v5.16.3;

use strict;
use warnings;

use Moo;
use Data::Dumper;
use Const::Fast;
use Wiki::JSON::Parser;
use Wiki::JSON::HTML;

our $VERSION = "0.0.28";

const my $MAX_HX_SIZE                                           => 6;
const my $EXTRA_CHARACTERS_BOLD_AND_ITALIC_WHEN_ITALIC          => 3;
const my $LIST_ELEMENT_INTERRUPT_NUMBER_OF_CHARACTERS_TO_IGNORE => 3;
const my $MINIMUM_LINK_SEARCH                                   => 3;
const my $MINIMUM_TEMPLATE_SEARCH                               => 3;
const my $LIST_ELEMENT_DELIMITER                                => "\n* ";

sub parse {
    my ( $self, $wiki_text ) = @_;
    return Wiki::JSON::Parser->new->parse($wiki_text);
}

sub pre_html {
    my ($self, $wiki_text, $template_callbacks) = @_;
    $template_callbacks //= {};
    $template_callbacks->{is_inline} //= sub { return 1; };
    $template_callbacks->{generate_elements} //= sub {};
    return Wiki::JSON::HTML->new->pre_html_json($wiki_text, $template_callbacks);
}
1;

=encoding utf8

=head1 NAME

Wiki::JSON - Parse wiki-like articles to a data-structure transformable to JSON.

=head1 SYNOPSIS

    use Wiki::JSON;

    my $structure = Wiki::JSON->new->parse(<<'EOF');
    = This is a wiki title =
    '''This is bold'''
    ''This is italic''
    '''''This is bold and italic'''''
    == This is a smaller title, the user can use no more than 6 equal signs ==
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
    This is a link to a URL with an alias: [[https://example.com/cool-source.html|cool article]]
    This is a link to a Image [[File:https:/example.com/img.png|50x50px|frame|This is a caption]]
    EOF

=head1 DESCRIPTION

A parser for a subset of a mediawiki-like syntax, quirks include some
supposedly inline elements are parsed multi-line like headers, templates*,
italic and bolds.

Lists are only one level and not everything in mediawiki is supported by the
moment.

=head2 INSTALLING

    cpanm https://github.com/sergiotarxz/Perl-Wiki-JSON.git

=head2 USING AS A COMMAND

    wiki2json file.wiki > output.json

=head1 INSTANCE METHODS

=head2 new

    my $wiki_parser = Wiki::JSON->new;

=head1 SUBROUTINES/METHODS

=head2 parse

    my $structure = $wiki_parser->parse($wiki_string);

Parses the wiki format into a serializable to JSON or YAML Perl data structure.

=head2 pre_html

    my $template_callbacks = {
        generate_elements => sub {
            my ( $template, $options, $parse_sub, $open_html_element_sub,
                $close_html_element_sub )
              = @_;
            my @dom;
            if ( $element->{template_name} eq 'stub' ) {
                push @dom,
                  $open_html_element_sub->( 'span', 0, { style => 'color: red;' } );
                push @dom, @{ $element->{output} };
                push @dom, $close_html_element_sub->('span');
            }
            return \@dom;
        },
        is_inline => sub {
            my ($template) = @_;
            if ($template->{template_name} eq 'stub') {
                return 1;
            }
            if ($template->{template_name} eq 'videoplayer') {
                return 0;
            }
        }
    };

    my $structure = $wiki_parser->pre_html($wiki_string, $template_callbacks);

Retrieves an ArrayRef containing just HashRefs without nesting describing how HTML tags should be open and closed for a wiki text.

=head3 template_callbacks

An optional hashref containing any or both of this two keys pointing to subrefs

=head1 RETURN FROM METHODS

=head2 parse

The return is an ArrayRef in which each element is either a string or a HashRef.

HashRefs can be classified by the key type which can be one of these:

=head3 hx

A header to be printed as h1..h6 in HTML, has the following fields:

=over 4

=item hx_level

A number from 1 to 6 defining the header level.

=item output

An ArrayRef defined by the return from parse.

=back

=head3 template

A template thought for developer defined expansions of how some data shoudl be represented.

=over 4

=item template_name

The name of the template.

=item output

An ArrayRef defined by the return from parse.

=back

=head3 bold

A set of elements that must be represented as bold text.

=over 4

=item output

An ArrayRef defined by the return from parse.

=back

=head3 italic

A set of elements that must be represented as italic text.

=over 4

=item output

An ArrayRef defined by the return from parse.

=back

=head3 bold_and_italic

A set of elements that must be represented as bold and italic text.

=over 4

=item output

An ArrayRef defined by the return from parse.

=back

=head3 unordered_list

A bullet point list.

=over 4

=item output

A ArrayRef of HashRefs from the type list_element.

=back

=head3 list_element

An element in a list, this element must not appear outside of the output element of a list.

=over 4

=item output

An ArrayRef defined by the return from parse.

=back

=head3 link

An URL or a link to other Wiki Article.

=over 4

=item link

The String containing the URL or link to other Wiki Article.

=item title

The text that should be used while showing this URL to point the user where it is going to be directed.

=back

=head3 image

An Image, PDF, or Video.

=over 4

=item link

Where to find the File.

=item caption

What to show the user if the image is requested to explain to the user what he is seeing.

=item options

=back

Undocumented by the moment.

=head1 DEPENDENCIES

The module will pull all the dependencies it needs on install, the minimum supported Perl is v5.16.3, although latest versions are mostly tested for 5.38.2

=head1 CONFIGURATION AND ENVIRONMENT

If your OS Perl is too old perlbrew can be used instead.

=head1 BUGS AND LIMITATIONS

The author thinks it is possible the parser hanging forever, use it in
a subprocess the program can kill if it takes too long.

The developer can use fork, waitpid, pipe, and non-blocking IO for that.

=head1 DIAGNOSTICS

If a string halting forever this module is found, send it to me in the Github issue tracker.

=head1 LICENSE AND COPYRIGHT

    Copyright ©Sergiotarxz (2025)

Licensed under the The GNU General Public License, Version 3, June 2007 L<http://www.gnu.org/licenses/gpl-3.0.txt>.

You can use this software under the terms of the GPLv3 license or a new later
version provided by the FSF or the GNU project.

=head1 INCOMPATIBILITIES

None known.

=head1 VERSION

0.0.x

=head1 AUTHOR

Sergio Iglesias

=head1 SEE ALSO

Look what is supported and how in the tests: L<https://github.com/sergiotarxz/Perl-Wiki-JSON/tree/main/t>

=cut
