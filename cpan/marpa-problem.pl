use v5.10;
use strict;
use warnings;

use Marpa::R2;

my $syntax = <<'END';
:default ::= action => ::first
:start ::= content
content ::= name ':' value
name ~ [A-Za-z0-9-]+
value ~ [A-Za-z0-9:-]+
END

my $grammar = Marpa::R2::Scanless::G->new( { source => \$syntax } );
say "rules G0:\n", $grammar->show_rules(1, 'G0');

my $recce = Marpa::R2::Scanless::R->new(
    { grammar => $grammar, semantics_package => 'Parse::vCard::Actions::v4', trace_terminals => 1 } );
my $input = do { local $/; <DATA> };
eval { $recce->read( \$input ); 1 }
    or do { say "\nprogress:\n", $recce->show_progress( 0, -1 ); die $@ };

__DATA__
UID:urn:uuid:4fbe8971-0bc3-424c-9c26-36c3e1eff6b1
