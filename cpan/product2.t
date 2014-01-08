#!/usr/bin/env perl

use 5.010;
use Marpa::R2;
use Data::Dumper;

my $source = <<'SOURCE';
product ::= sku nl name nl price price price nl

sku       ~ sku_0 '.' sku_0
sku_0     ~ [\d]+

price     ~ price_0 ',' price_0
price_0   ~ [\d]+
nl        ~ [\n]

sp        ~ [ ]+
:discard  ~ sp

:lexeme ~ <name> forgiving => 1
name      ~ [^\n]+

SOURCE

my $g = Marpa::R2::Scanless::G->new({
    source => \$source,
    default_action => '::array',
});

my $input = <<'INPUT';
130.12312
Descriptive line
1,10 1,10 1,30
INPUT

my $slr =
    Marpa::R2::Scanless::R->new( { grammar => $g,
   #  trace_terminals => 1
   } );
$slr->read( \$input );
print Dumper([ ${$slr->value} ]); 

# vim: set expandtab shiftwidth=4:
