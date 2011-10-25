#!perl
# This software is copyright (c) 2011 by Jeffrey Kegler
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

use 5.010;
use warnings;
use strict;

use Test::More tests => 2;

use Carp;
use Data::Dumper;

Test::More::use_ok('Marpa::R2::HTML');

Test::More::diag( 'Using Marpa::R2::HTML ', $Marpa::R2::HTML::VERSION );

Test::More::ok( defined $Marpa::R2::TIMESTAMP,
    'Marpa::XS Timestamp defined' );
Test::More::diag( 'Using Marpa::R2 ',
    $Marpa::R2::VERSION, q{ }, $Marpa::R2::TIMESTAMP );

1;    # In case used as "do" file

