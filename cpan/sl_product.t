#!/usr/bin/env perl

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

{ current lexer is 'slurp name' }
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

my $re = Marpa::R2::Scanless::R->new({ grammar => $g, trace_terminals => 1 }); 
$re->read(\$input);


print Dumper([ ${$re->value} ]); 
