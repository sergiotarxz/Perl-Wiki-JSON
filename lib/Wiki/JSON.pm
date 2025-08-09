package Wiki::JSON;

use v5.38.2;

use strict;
use warnings;

use Moo;
use Data::Dumper;

sub parse( $self, $wiki_text ) {
    my @output;
    $self->_parse_in_array( \@output, $wiki_text );
    return \@output;
}

sub _search_interrupt( $self, $output, $buffer, $wiki_text, $i, $interrupt ) {
    my $new_i = $interrupt->( $wiki_text, $i );
    {
        {
            if ( !defined $new_i ) {
                next;
            }
            $i = $new_i;
            return $i;
        }
    }
    return;
}

sub _break_lines( $self, $output, $buffer, $current_char, ) {
    if ( $current_char eq "\n" ) {
        push @$output, $buffer;
        return ( 1, '' );
    }
    return ( 0, $buffer );
}

sub _parse_in_array(
    $self, $output, $wiki_text, $i = 0,
    $buffer = '',
    $interrupt = sub { return; },
    $options = {}
  )
{
    for ( ; $i < length $wiki_text ; $i++ ) {
        my $new_i;
        $new_i = $self->_search_interrupt( $output, $buffer, $wiki_text, $i,
            $interrupt );
        if ( defined $new_i ) {
            if (!$options->{is_nowiki}) {
                push @$output, $buffer;
                $buffer = '';
            }
            return ($new_i, $buffer);
        }
        my $current_char = substr $wiki_text, $i, 1;
        my $needs_newline;
        ( $needs_newline, $buffer ) =
          $self->_break_lines( $output, $buffer, $current_char );
        if ($needs_newline) {
            next;
        }
        if ( !$options->{is_nowiki} ) {
            if ( !$options->{is_header} ) {
                my $got_something;
                ( $got_something, $i, $buffer ) =
                  $self->_try_parse_header( $output, $wiki_text,
                    $buffer, $i );
                if ($got_something) {
                    next;
                }
            }
            my $got_something;
            ( $got_something, $i, $buffer ) =
              $self->_try_parse_nowiki( $output, $wiki_text,
                $buffer, $i );
            if ($got_something) {
                next;
            }
        }
        $buffer .= $current_char;
    }
    if (!$options->{is_nowiki} && length $buffer) {
        push @$output, $buffer;
        $buffer = '';
    }
    return ($i, $buffer);
}

sub _try_parse_nowiki( $self, $output, $wiki_text, $buffer, $i ) {
    my $tag = '<nowiki>';
    my $next_word = substr $wiki_text, $i, length $tag;
    if ($tag ne $next_word) {
        return (0, $i, $buffer);
    }
    $i += length $tag;
    ($i, $buffer) = $self->_parse_in_array(
        $output,
        $wiki_text,
        $i,
        $buffer,
        sub ( $wiki_text, $i ) {
            my $tag = '</nowiki>';
            my $next_word = substr $wiki_text, $i, length $tag;
            if ($tag ne $next_word) {
                return;
            }
            return $i + (length $tag) - 1;
        },
        { is_nowiki => 1 }
    );
    return ( 1, $i, $buffer );
}

sub _try_parse_header( $self, $output, $wiki_text, $buffer, $i ) {
    my $last_char = substr $wiki_text, $i, 1;
    if ( $last_char ne '=' ) {
        return ( 0, $i, $buffer );
    }
    if ( length $buffer ) {
        push @$output, $buffer;
        $buffer = '';
    }
    my $matching = 1;
    while (1) {
        my $last_chars = substr $wiki_text, $i, $matching + 1;
        if ( $last_chars ne ( '=' x ( $matching + 1 ) ) ) {
            last;
        }
        $matching++;
        if ( $matching > 6 ) {
            $matching = 6;
            last;
        }
        if ( $i + $matching > length $wiki_text ) {
            $matching--;
            last;
        }
    }
    $i += $matching;
    my $header = {
        hx_level => $matching,
        output   => [],
        type     => 'hx',
    };
    ($i, $buffer) = $self->_parse_in_array(
        $header->{output},
        $wiki_text,
        $i,
        $buffer,
        sub ( $wiki_text, $i ) {
            my $char = substr $wiki_text, $i, 1;
            if ( $char eq "\n" ) {
                return $i;
            }
            if ( $char ne '=' ) {
                return;
            }
            for ( ; $i < length $wiki_text ; $i++ ) {
                if ( "\n" eq substr $wiki_text, $i, 1 ) {
                    return $i;
                }

                if ( '=' ne substr $wiki_text, $i, 1 ) {
                    return --$i;
                }
            }
            return $i;
        },
        { is_header => 1 }
    );
    push @$output, $header;
    return ( 1, $i, $buffer );
}
1;
