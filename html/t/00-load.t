#!perl
# This software is copyright (c) 2011 by Jeffrey Kegler
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

use 5.010;
use warnings;
use strict;

use Test::More tests => 3;

use Carp;
use Data::Dumper;

Test::More::use_ok('Marpa::HTML');

SKIP: {
   skip "Not Using PP", 1 if $Marpa::USING_XS;
   Test::More::ok( $Marpa::USING_PP, 'Using PP' );
   Test::More::diag('Using PP ', $Marpa::PP::VERSION);
}

SKIP: {
   skip "Not Using XS", 1 if $Marpa::USING_PP;
   Test::More::ok( $Marpa::USING_XS, 'Using XS' );
   Test::More::diag('Using XS ', $Marpa::XS::VERSION);
}

1;    # In case used as "do" file

