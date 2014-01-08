#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Marpa::R2;
use Data::Dumper;

my $source = <<'END';
:default ::= action => ::array
:start ::= content
content ::= name ':' value
name ~ [A-Za-z0-9-]+
value ~ [A-Za-z0-9:-]+
:lexeme ~ value forgiving => 1
END

my $g = Marpa::R2::Scanless::G->new({
    source => \$source
});

my $input = 'UID:urn:uuid:4fbe8971-0bc3-424c-9c26-36c3e1eff6b1';

my $slr =
    Marpa::R2::Scanless::R->new( { grammar => $g,
   #  trace_terminals => 1
   } );
$slr->read( \$input );
print Dumper([ ${$slr->value} ]); 

# vim: set expandtab shiftwidth=4:
