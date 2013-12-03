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

event '^name' = predicted <name>
:lexeme ~ <name> pause => after event => 'name$'
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

my $slr =
    Marpa::R2::Scanless::R->new( { grammar => $g, trace_terminals => 1 } );
my $length = length $input;
for ( my $pos = $slr->read( \$input ); $pos < $length; $pos = $slr->resume() ) {
    EVENT:
    for my $event ( @{ $slr->events() } ) {
        my ($name) = @{$event};
        say "Event: ", $name;
	exit 0;
    }
}

print Dumper([ ${$slr->value} ]); 
