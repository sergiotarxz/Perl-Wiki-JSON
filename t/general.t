use v5.16.3;

use strict;
use warnings;

use lib 'lib';

use Test::Most;
use Test::Warnings;

use_ok 'Wiki::JSON';

{
    my $parsed = Wiki::JSON->new->parse(
        q(= This is a wiki title =
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
Let's end them '' == '''
 )
    );

    is_deeply $parsed, [
        {
            'type'     => 'hx',
            'output'   => ['This is a wiki title'],
            'hx_level' => 1
        },
        {
            'output' => ['This is bold'],
            'type'   => 'bold'
        },
        {
            'type'   => 'italic',
            'output' => ['This is italic']
        },
        {
            'type'   => 'bold_and_italic',
            'output' => ['This is bold and italic']
        },
        {
            'output' => [
'This is a smaller title, the user can use no more than 6 equal signs'
            ],
            'type'     => 'hx',
            'hx_level' => 2
        },
        '\'\'This is printed without expanding the special characters',
        {
            'output' => [
                {
                    'type'   => 'list_element',
                    'output' => ['This']
                },
                {
                    'output' => ['Is'],
                    'type'   => 'list_element'
                },
                {
                    'type'   => 'list_element',
                    'output' => ['A']
                },
                {
                    'output' => ['Bullet'],
                    'type'   => 'list_element'
                },
                {
                    'output' => ['Point'],
                    'type'   => 'list_element'
                },
                {
                    'output' => ['List'],
                    'type'   => 'list_element'
                }
            ],
            'type' => 'unordered_list'
        },
        {
            'type'   => 'template',
            'output' => [ 'Templates are generated', 'with their arguments' ],
            'template_name' => 'foo'
        },
        {
            'template_name' => 'stub',
            'type'          => 'template',
            'output'        => ['This is under heavy development']
        },
        'The parser has some quirks ',
        {
            'type'     => 'hx',
            'hx_level' => 2,
            'output'   => ['This will generate a title']
        },
        {
            'type'   => 'bold',
            'output' => [
                ' ',
                {
                    'type'     => 'hx',
                    'hx_level' => 2,
                    'output'   => [
                        {
                            'output' => [
' Unterminated syntaxes will still be parsed until the end of file
This is a link to a wiki article: ',
                                {
                                    'title' => 'Cool Article',
                                    'link'  => 'Cool Article',
                                    'type'  => 'link'
                                },
'This is a link to a wiki article with an alias: ',
                                {
                                    'type'  => 'link',
                                    'link'  => 'Cool Article',
                                    'title' => 'cool article'
                                },
                                'This is a link to a URL with an alias: ',
                                {
                                    'link' =>
                                      'https://example.com/cool-source.html',
                                    'type'  => 'link',
                                    'title' => 'cool article'
                                },
                                'This is a link to a Image ',
                                {
                                    'caption' => 'This is a caption',
                                    'options' => {
                                        'format' => {
                                            'frame' => 1
                                        },
                                        'resize' => {
                                            'height' => 50,
                                            'width'  => 50
                                        }
                                    },
                                    'link' => 'https:/example.com/img.png',
                                    'type' => 'image'
                                },
                                'Let\'s end them ',
                            ],
                            'type' => 'italic'
                        },
                    ]
                },
                ' ',
            ]
        },
        ' ',
      ],
      'Demo wiki works';
}

{
    my $warnings = Test::Warnings::warning {
        my $parsed_html = Wiki::JSON->new->pre_html(
            q@= This is a (level 1) wiki title =
== This is a (level 2) wiki subtitle ==
This is a paragraph of text. This is '''bold text''', while this is ''italic 
text''. Combine the two into '''''bold and italic text'''''.
More text in this paragraph follows.

Another paragraph here.
<nowiki>''This is printed without expanding the special characters.</nowiki>
You would want to do that if you happen to have Wiki controls within your
text.

* This
* Is
* A
* Bullet
* Point
* List

== Other stuff ==
Start another paragraph. {{foo|Templates are generated|with their arguments}}
{{stub|This is under heavy development}}
The parser has some quirks == This will generate a title == even though it
is in the middle of a paragraph.
''' == '' Unterminated syntaxes will still be parsed until the end of paragraph.

A paragraph with links:
This is a link to a wiki article: [[Cool Article]].
This is a link to a wiki article with an alias: [[Cooler Article|cooler article]].
This is a link to a URL with an alias: [[https://example.com/cool-source.html|cool article]].
This is a link to an Image: [[File:https:/example.com/img.png|50x50px|frame|This is a caption]].

=== Level 3 subheading ===
Let's end here.@
        );
#        print STDERR Data::Dumper::Dumper( $parsed_html->[63] );

        is_deeply $parsed_html,
          [
            {
                'status' => 'open',
                'tag'    => 'article',
                'attrs'  => {
                    'class' => 'wiki-article'
                }
            },
            {
                'attrs'  => {},
                'tag'    => 'h1',
                'status' => 'open'
            },
            'This is a (level 1) wiki title',
            {
                'tag'    => 'h1',
                'status' => 'close'
            },
            {
                'tag'    => 'h2',
                'status' => 'open',
                'attrs'  => {}
            },
            'This is a (level 2) wiki subtitle',
            {
                'tag'    => 'h2',
                'status' => 'close'
            },
            {
                'attrs'  => {},
                'tag'    => 'p',
                'status' => 'open'
            },
            'This is a paragraph of text. This is ',
            {
                'attrs'  => {},
                'status' => 'open',
                'tag'    => 'b'
            },
            'bold text',
            {
                'tag'    => 'b',
                'status' => 'close'
            },
            ', while this is ',
            {
                'tag'    => 'i',
                'status' => 'open',
                'attrs'  => {}
            },
            'italic text',
            {
                'tag'    => 'i',
                'status' => 'close'
            },
            '. Combine the two into ',
            {
                'attrs'  => {},
                'status' => 'open',
                'tag'    => 'b'
            },
            {
                'tag'    => 'i',
                'status' => 'open',
                'attrs'  => {}
            },
            'bold and italic text',
            {
                'status' => 'close',
                'tag'    => 'i'
            },
            {
                'status' => 'close',
                'tag'    => 'b'
            },
            '. More text in this paragraph follows.',
            {
                'status' => 'close',
                'tag'    => 'p'
            },
            {
                'status' => 'open',
                'tag'    => 'p',
                'attrs'  => {}
            },
'Another paragraph here. \'\'This is printed without expanding the special characters. You would want to do that if you happen to have Wiki controls within your text.',
            {
                'status' => 'close',
                'tag'    => 'p'
            },
            {
                'status' => 'open',
                'tag'    => 'ul',
                'attrs'  => {}
            },
            {
                'tag'    => 'li',
                'status' => 'open',
                'attrs'  => {}
            },
            'This',
            {
                'status' => 'close',
                'tag'    => 'li'
            },
            {
                'tag'    => 'li',
                'status' => 'open',
                'attrs'  => {}
            },
            'Is',
            {
                'status' => 'close',
                'tag'    => 'li'
            },
            {
                'attrs'  => {},
                'status' => 'open',
                'tag'    => 'li'
            },
            'A',
            {
                'tag'    => 'li',
                'status' => 'close'
            },
            {
                'status' => 'open',
                'tag'    => 'li',
                'attrs'  => {}
            },
            'Bullet',
            {
                'tag'    => 'li',
                'status' => 'close'
            },
            {
                'tag'    => 'li',
                'status' => 'open',
                'attrs'  => {}
            },
            'Point',
            {
                'status' => 'close',
                'tag'    => 'li'
            },
            {
                'tag'    => 'li',
                'status' => 'open',
                'attrs'  => {}
            },
            'List',
            {
                'status' => 'close',
                'tag'    => 'li'
            },
            {
                'status' => 'close',
                'tag'    => 'ul'
            },
            {
                'tag'    => 'h2',
                'status' => 'open',
                'attrs'  => {}
            },
            'Other stuff',
            {
                'status' => 'close',
                'tag'    => 'h2'
            },
            {
                'status' => 'open',
                'tag'    => 'p',
                'attrs'  => {}
            },
            'Start another paragraph. ',
            'The parser has some quirks ',
            {
                'tag'    => 'p',
                'status' => 'close'
            },
            {
                'status' => 'open',
                'tag'    => 'h2',
                'attrs'  => {}
            },
            'This will generate a title',
            {
                'status' => 'close',
                'tag'    => 'h2'
            },
            {
                'tag'    => 'p',
                'status' => 'open',
                'attrs'  => {}
            },
            ' even though it is in the middle of a paragraph. ',
            {
                status => 'open',
                tag    => 'b',
                attrs  => {},
            },
            ' ',
            {
                'status' => 'open',
                'tag'    => 'h2',
                'attrs'  => {}
            },
            {
                'attrs'  => {},
                'status' => 'open',
                'tag'    => 'i'
            },
' Unterminated syntaxes will still be parsed until the end of paragraph.',
            {
                'attrs'  => {},
                'tag'    => 'br',
                'status' => 'self-close'
            },
            'A paragraph with links: This is a link to a wiki article: ',
            {
                'attrs' => {
                    'href' => '/Cool%20Article'
                },
                'tag'    => 'a',
                'status' => 'open'
            },
            'Cool Article',
            {
                'status' => 'close',
                'tag'    => 'a'
            },
            '. This is a link to a wiki article with an alias: ',
            {
                'attrs' => {
                    'href' => '/Cooler%20Article'
                },
                'tag'    => 'a',
                'status' => 'open'
            },
            'cooler article',
            {
                'status' => 'close',
                'tag'    => 'a'
            },
            '. This is a link to a URL with an alias: ',
            {
                'attrs' => {
                    'href' => '/https://example.com/cool-source.html'
                },
                'tag'    => 'a',
                'status' => 'open'
            },
            'cool article',
            {
                'status' => 'close',
                'tag'    => 'a'
            },
            '. This is a link to an Image: ',
            {
                'attrs' => {
                    'typeof' => 'mw:File/Frame'
                },
                'tag'    => 'figure',
                'status' => 'open'
            },
            {
                'attrs' => {
                    'src' => 'https:/example.com/img.png'
                },
                'status' => 'self-close',
                'tag'    => 'img'
            },
            {
                'status' => 'open',
                'tag'    => 'figcaption',
                'attrs'  => {}
            },
            'This is a caption',
            {
                'tag'    => 'figcaption',
                'status' => 'close'
            },
            {
                'status' => 'close',
                'tag'    => 'figure'
            },
            {
                'attrs'  => {},
                'tag'    => 'br',
                'status' => 'self-close'
            },
            '.',
            {
                'attrs'  => {},
                'status' => 'open',
                'tag'    => 'h3'
            },
            'Level 3 subheading',
            {
                'tag'    => 'h3',
                'status' => 'close'
            },
            {
                'status' => 'self-close',
                'tag'    => 'br',
                'attrs'  => {}
            },
            'Let\'s end here.',
            {
                'tag'    => 'i',
                'status' => 'close'
            },
            {
                'tag'    => 'h2',
                'status' => 'close'
            },
            {
                'status' => 'close',
                'tag'    => 'b'
            },
            {
                'tag'    => 'p',
                'status' => 'close'
            },
            {
                'status' => 'close',
                'tag'    => 'article'
            }
          ];
    };
    like $warnings->[0], qr/Detected bold or italic unterminated syntax/,
      'Unterminated syntax caught';
    like $warnings->[1], qr/Detected bold or italic unterminated syntax/,
      'Unterminated syntax caught';
    like $warnings->[2], qr/Detected bold or italic unterminated syntax/,
      'Unterminated syntax caught';
    like $warnings->[3], qr/Detected bold or italic unterminated syntax/,
      'Unterminated syntax caught';
    like $warnings->[4], qr/HX found when the content is expected to be inline/,
      'Block element detected inside inline';
    like $warnings->[5],
      qr/Image found when the content is expected to be inline/,
      'Block element detected inside inline';
    like $warnings->[6], qr/HX found when the content is expected to be inline/,
      'Block element detected inside inline';
}
done_testing();
