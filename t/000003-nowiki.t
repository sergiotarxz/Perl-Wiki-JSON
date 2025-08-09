use v5.38.2;

use strict;
use warnings;

use lib 'lib';

use Test::Most;

use_ok 'Wiki::JSON';

{
        my $parsed =
          Wiki::JSON->new->parse( '<nowiki>=== hola ===</nowiki>');
        is_deeply $parsed,
          [
            '=== hola ==='
          ],

          'Simple nowiki works';
}

{
        my $parsed =
      Wiki::JSON->new->parse( 'hola
This is how titles are made: <nowiki>=== hola ===</nowiki> Cool isn\'t it?
hola');
        print STDERR Data::Dumper::Dumper $parsed;
        is_deeply $parsed,
          [
            'hola',
            'This is how titles are made: === hola === Cool isn\'t it?',
            'hola',
          ],

          'Simple nowiki works';
}
done_testing();
