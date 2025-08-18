use v5.16.3;

use strict;
use warnings;

use lib 'lib';

use Test::Most;

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

#    print STDERR Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [ 
          {
            'type' => 'hx',
            'output' => [
                          'This is a wiki title'
                        ],
            'hx_level' => 1
          },
          {
            'output' => [
                          'This is bold'
                        ],
            'type' => 'bold'
          },
          {
            'type' => 'italic',
            'output' => [
                          'This is italic'
                        ]
          },
          {
            'type' => 'bold_and_italic',
            'output' => [
                          'This is bold and italic'
                        ]
          },
          {
            'output' => [
                          'This is a smaller title, the user can use no more than 6 equal signs'
                        ],
            'type' => 'hx',
            'hx_level' => 2
          },
          '\'\'This is printed without expanding the special characters',
          {
            'output' => [
                          {
                            'type' => 'list_element',
                            'output' => [
                                          'This'
                                        ]
                          },
                          {
                            'output' => [
                                          'Is'
                                        ],
                            'type' => 'list_element'
                          },
                          {
                            'type' => 'list_element',
                            'output' => [
                                          'A'
                                        ]
                          },
                          {
                            'output' => [
                                          'Bullet'
                                        ],
                            'type' => 'list_element'
                          },
                          {
                            'output' => [
                                          'Point'
                                        ],
                            'type' => 'list_element'
                          },
                          {
                            'output' => [
                                          'List'
                                        ],
                            'type' => 'list_element'
                          }
                        ],
            'type' => 'unordered_list'
          },
          {
            'type' => 'template',
            'output' => [
                          'Templates are generated',
                          'with their arguments'
                        ],
            'template_name' => 'foo'
          },
          {
            'template_name' => 'stub',
            'type' => 'template',
            'output' => [
                          'This is under heavy development'
                        ]
          },
          'The parser has some quirks ',
          {
            'type' => 'hx',
            'hx_level' => 2,
            'output' => [
                          'This will generate a title'
                        ]
          },
          {
            'type' => 'bold',
            'output' => [
                          ' ',
                          {
                            'type' => 'hx',
                            'hx_level' => 2,
                            'output' => [
                                          {
                                            'output' => [
                                                          ' Unterminated syntaxes will still be parsed until the end of file',
                                                          'This is a link to a wiki article: ',
                                                          {
                                                            'title' => 'Cool Article',
                                                            'link' => 'Cool Article',
                                                            'type' => 'link'
                                                          },
                                                          'This is a link to a wiki article with an alias: ',
                                                          {
                                                            'type' => 'link',
                                                            'link' => 'Cool Article',
                                                            'title' => 'cool article'
                                                          },
                                                          'This is a link to a URL with an alias: ',
                                                          {
                                                            'link' => 'https://example.com/cool-source.html',
                                                            'type' => 'link',
                                                            'title' => 'cool article'
                                                          },
                                                          'This is a link to a Image ',
                                                          {
                                                            'caption' => 'frame',
                                                            'options' => {
                                                                           'format' => {
                                                                                         'frame' => 1
                                                                                       },
                                                                           'resize' => {
                                                                                         'height' => 50,
                                                                                         'width' => 50
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
     ], 'Demo wiki works';
}
done_testing();
