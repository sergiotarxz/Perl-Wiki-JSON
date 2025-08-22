package Wiki::JSON::HTML;

use v5.38.2;

use strict;
use warnings;

use Moo;
use Mojo::DOM;
use Mojo::Util qw/xml_escape/;

has _wiki_json => ( is => 'lazy' );

sub pre_html_json {
    my ( $self, $wiki_text ) = @_;
    my @dom;
    push @dom,
      $self->_open_html_element( 'article', 0, { class => 'wiki-article' } );
    my $json = $self->_wiki_json->parse($wiki_text);

    # print Data::Dumper::Dumper $json;
    push @dom, @{ $self->_parse_output($json) };
    push @dom, $self->_close_html_element('article');
    return \@dom;
}

sub _build__wiki_json {
    my $self = shift;
    require Wiki::JSON;
    return Wiki::JSON->new;
}

sub _open_html_element {
    if ( @_ < 2 ) {
        die '_open_html_element needs $self and $tag at least as arguments';
    }
    my ( $self, $tag, $self_closing, $attributes ) = @_;
    $self_closing //= 0;
    $attributes   //= {};
    if ( 'HASH' ne ref $attributes ) {
        die 'HTML attributes are not a HASHREF';
    }
    return {
        tag    => $tag,
        status => $self_closing ? 'self-close' : 'open',
        attrs  => $attributes,
    };
}

sub _close_html_element {
    if ( @_ != 2 ) {
        die
'_close_html_element accepts exactly the following arguments $self and $tag';
    }
    my ( $self, $tag ) = @_;
    return {
        tag    => $tag,
        status => 'close',
    };
}

sub _html_string_content_to_pushable {
    my ( $self, $content ) = @_;
    $content =~ s/(?:\r|\n)/ /gs;
    $content =~ s/ +/ /gs;
    return $content;
}

sub _parse_output_try_parse_plain_text {
    if ( @_ != 6 ) {
        die
'_parse_output_try_parse_plain_text needs $self, $dom, $element, $last_element_inline_element, $needs_closing_parragraph, $options';
    }
    my ( $self, $dom, $element, $last_element_inline_element,
        $needs_closing_parragraph, $options )
      = @_;
    my $needs_next = 0;
    if ( 'HASH' ne ref $element ) {
        if ( !$last_element_inline_element ) {
            ($needs_closing_parragraph) =
              $self->_close_parragraph( $dom, $needs_closing_parragraph,
                $options );
        }
        if ($element) {
            ($needs_closing_parragraph) =
              $self->_open_parragraph( $dom, $needs_closing_parragraph,
                $options );
            push @$dom, $self->_html_string_content_to_pushable($element);
        }
        $needs_next = 1;
    }
    return ( $needs_next, $needs_closing_parragraph );
}

sub _parse_output_try_parse_italic {
    if ( @_ < 6 ) {
        die 'Incorrect arguments _parse_output_try_parse_italic';
    }
    my ( $self, $dom, $element, $found_inline_element,
        $needs_closing_parragraph, $options )
      = @_;
    my $needs_next;
    if ( $element->{type} eq 'italic' ) {
        ($needs_closing_parragraph) =
          $self->_open_parragraph( $dom, $needs_closing_parragraph, $options );
        $found_inline_element = 1;
        push @$dom, $self->_open_html_element('i');
        push @$dom,
          @{
            $self->_parse_output( $element->{output},
                { inside_inline_element => 1 } )
          };
        push @$dom, $self->_close_html_element('i');
        $needs_next = 1;
    }
    return ( $needs_next, $needs_closing_parragraph, $found_inline_element );
}

sub _parse_output_try_parse_bold_and_italic {
    if ( @_ < 6 ) {
        die 'Incorrect arguments _parse_output_try_parse_bold_and_italic';
    }
    my ( $self, $dom, $element, $found_inline_element,
        $needs_closing_parragraph, $options )
      = @_;
    my $needs_next;
    if ( $element->{type} eq 'bold_and_italic' ) {
        ($needs_closing_parragraph) =
          $self->_open_parragraph( $dom, $needs_closing_parragraph, $options );
        $found_inline_element = 1;
        push @$dom, $self->_open_html_element('b');
        push @$dom, $self->_open_html_element('i');
        push @$dom,
          @{
            $self->_parse_output( $element->{output},
                { inside_inline_element => 1 } )
          };
        push @$dom, $self->_close_html_element('i');
        push @$dom, $self->_close_html_element('b');
        $needs_next = 1;
    }
    return ( $needs_next, $needs_closing_parragraph, $found_inline_element );
}

sub _parse_output_try_parse_bold {
    if ( @_ < 6 ) {
        die 'Incorrect arguments _parse_output_try_parse_bold';
    }
    my ( $self, $dom, $element, $found_inline_element,
        $needs_closing_parragraph, $options )
      = @_;
    my $needs_next;
    if ( $element->{type} eq 'bold' ) {
        ($needs_closing_parragraph) =
          $self->_open_parragraph( $dom, $needs_closing_parragraph, $options );
        $found_inline_element = 1;
        push @$dom, $self->_open_html_element('b');
        push @$dom,
          @{
            $self->_parse_output( $element->{output},
                { inside_inline_element => 1 } )
          };
        push @$dom, $self->_close_html_element('b');
        $needs_next = 1;
    }

    return ( $needs_next, $needs_closing_parragraph, $found_inline_element );
}

sub _parse_output_try_parse_link {
    if ( @_ < 6 ) {
        die 'Incorrect arguments';
    }
    my ( $self, $dom, $element, $needs_closing_parragraph, $found_inline_element, $options ) = @_;
    my $needs_next;
    if ( $element->{type} eq 'link' ) {
        ($needs_closing_parragraph) =
          $self->_open_parragraph( $dom, $needs_closing_parragraph, $options );
        $found_inline_element = 1;
        my $real_link = $element->{link};
        if ( $real_link !~ /^\w:/ && $real_link !~ m@^(?:/|\w+\.)@ ) {

            # TODO: Allow setting a base URL.
            $real_link = '/' . $real_link;
        }
        push @$dom, $self->_open_html_element( 'a', 0, { href => $real_link } );
        push @$dom,
          $self->_html_string_content_to_pushable( $element->{title} );
        push @$dom, $self->_close_html_element('a');
        $needs_next = 1;
    }
    return ( $needs_next, $needs_closing_parragraph, $found_inline_element );
}

sub _parse_output_try_parse_unordered_list {
    if ( @_ < 5 ) {
        die 'Incorrect number of parameters';
    }
    my ( $self, $dom, $element, $needs_closing_parragraph, $options ) = @_;
    my $needs_next;
    if ( $element->{type} eq 'unordered_list' ) {
        if ( $options->{inside_inline_element} ) {
            warn 'unordered list found when content is expected to be inline';
        }
        ($needs_closing_parragraph) =
          $self->_close_parragraph( $dom, $needs_closing_parragraph,
            $options );
        my $elements = $element->{output};
        push @$dom, $self->_open_html_element('ul');
        for my $element (@$elements) {
            push @$dom, $self->_open_html_element('li');
            push @$dom,
              @{
                $self->_parse_output( $element->{output},
                    { %$options, is_list_element => 1 } )
              };
            push @$dom, $self->_close_html_element('li');
        }
        push @$dom, $self->_close_html_element('ul');
        $needs_next = 1;
    }
    return ( $needs_next, $needs_closing_parragraph );
}

sub _parse_output_try_parse_hx {
    if ( @_ < 5 ) {
        die 'Incorrect arguments to _parse_output_try_parse_hx';
    }
    my ( $self, $dom, $element, $needs_closing_parragraph, $options ) = @_;
    my $needs_next;
    if ( $element->{type} eq 'hx' ) {
        if ( $options->{inside_inline_element} ) {
            warn 'HX found when the content is expected to be inline';
        }
        ($needs_closing_parragraph) =
          $self->_close_parragraph( $dom, $needs_closing_parragraph,
            $options );
        my $hx_level = $element->{hx_level};

        push @$dom, $self->_open_html_element( xml_escape "h$hx_level" );
        push @$dom,
          @{
            $self->_parse_output( $element->{output},
                { %$options, inside_inline_element => 1 } )
          };
        push @$dom, $self->_close_html_element( xml_escape "h$hx_level" );
        $needs_next = 1;
    }
    return ( $needs_next, $needs_closing_parragraph );
}

sub _parse_output {
    if ( @_ < 2 ) {
        die '_parse_output needs at least $self and $output';
    }
    my ( $self, $output, $options ) = @_;
    $options //= {};
    my @dom;
    my $needs_closing_parragraph = 0;
    my $first                    = 1;
    my $last_element_inline_element;
    for my $element (@$output) {
        my $found_inline_element;
        {
            my ($needs_next);
            $options->{first} = $first;
            ( $needs_next, $needs_closing_parragraph ) =
              $self->_parse_output_try_parse_plain_text( \@dom, $element,
                $last_element_inline_element, $needs_closing_parragraph,
                $options );
            next if $needs_next;

            ( $needs_next, $needs_closing_parragraph, $found_inline_element ) =
              $self->_parse_output_try_parse_bold( \@dom, $element,
                $found_inline_element, $needs_closing_parragraph, $options );
            next if $needs_next;
            ( $needs_next, $needs_closing_parragraph, $found_inline_element ) =
              $self->_parse_output_try_parse_bold_and_italic( \@dom, $element,
                $found_inline_element, $needs_closing_parragraph, $options );
            next if $needs_next;
            ( $needs_next, $needs_closing_parragraph, $found_inline_element ) =
              $self->_parse_output_try_parse_italic( \@dom, $element,
                $found_inline_element, $needs_closing_parragraph, $options );
            next if $needs_next;
            ( $needs_next, $needs_closing_parragraph ) =
              $self->_parse_output_try_parse_hx( \@dom, $element,
                $needs_closing_parragraph, $options );
            next if $needs_next;

            ( $needs_next, $needs_closing_parragraph ) =
              $self->_parse_output_try_parse_unordered_list( \@dom, $element,
                $needs_closing_parragraph, $options );
            next if $needs_next;
            ( $needs_next, $needs_closing_parragraph, $found_inline_element ) =
              $self->_parse_output_try_parse_link( \@dom, $element,
                $needs_closing_parragraph, $found_inline_element, $options );
            next if $needs_next;

        }
        $first                       = 0;
        $last_element_inline_element = !!$found_inline_element;
    }
    ($needs_closing_parragraph) =
      $self->_close_parragraph( \@dom, $needs_closing_parragraph, $options );
    return \@dom;
}

sub _open_parragraph {
    my ( $self, $dom, $needs_closing_parragraph, $options ) = @_;
    if ( $options->{is_list_element} || $options->{inside_inline_element} ) {
        if ( !$options->{first} ) {
            push @$dom, $self->_open_html_element( 'br', 1 );
        }
        return ($needs_closing_parragraph);
    }
    if ( !$needs_closing_parragraph ) {
        push @$dom, $self->_open_html_element('p');
        $needs_closing_parragraph = 1;
    }
    return ($needs_closing_parragraph);
}

sub _close_parragraph {
    my ( $self, $dom, $needs_closing_parragraph, $options ) = @_;
    if ($needs_closing_parragraph) {
        push @$dom, $self->_close_html_element('p');
        $needs_closing_parragraph = 0;
    }
    return ( $needs_closing_parragraph );
}
1
