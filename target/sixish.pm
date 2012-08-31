use 5.010;
use strict;
use warnings;

use Marpa::R2;

{
    my $file = './OP3.pm';
    unless ( my $return = do $file ) {
        warn "couldn't parse $file: $@" if $@;
        warn "couldn't do $file: $!" unless defined $return;
        warn "couldn't run $file" unless $return;
    }
}

sub sixish_new {
    my $sixish_grammar  = Marpa::R2::Thin::G->new( { if => 1 } );
    my $tracer          = Marpa::R2::Thin::Trace->new($sixish_grammar);
    my %char_to_symbol  = ();
    my @regex_to_symbol = ();

    $char_to_symbol{'*'}  = $tracer->symbol_new('star');
    $char_to_symbol{'<'}  = $tracer->symbol_new('langle');
    $char_to_symbol{'>'}  = $tracer->symbol_new('rangle');
    $char_to_symbol{q{'}} = $tracer->symbol_new('single_quote');
    $char_to_symbol{'~'}  = $tracer->symbol_new('tilde');

    my $s_ws_char = $tracer->symbol_new('ws_char');
    push @regex_to_symbol, [ qr/\s/xms, $s_ws_char ];
    my $s_single_quoted_char = $tracer->symbol_new('single_quoted_char');
    push @regex_to_symbol, [ qr/[^\\']/xms, $s_single_quoted_char ];

    $tracer->symbol_new('atom');
    $tracer->symbol_new('concatenation');
    $tracer->symbol_new('single_quoted_char_seq');
    $tracer->symbol_new('opt_ws');
    $tracer->symbol_new('quantified_atom');
    $tracer->symbol_new('quantifier');
    $tracer->symbol_new('quoted_literal');
    $tracer->symbol_new('self');
    $tracer->symbol_new('start');

    $tracer->rule_new('start ::= concatenation');
    $tracer->rule_new('concatenation ::=');
    $tracer->rule_new(
        'concatenation ::= concatenation opt_ws quantified_atom');
    $tracer->rule_new('opt_ws ::= ');
    $tracer->rule_new('opt_ws ::= opt_ws ws_char');
    $tracer->rule_new('quantified_atom ::= atom opt_ws quantifier');
    $tracer->rule_new('quantified_atom ::= atom');
    $tracer->rule_new('atom ::= quoted_literal');
    $tracer->rule_new(
        'quoted_literal ::= single_quote single_quoted_char_seq single_quote');
    $sixish_grammar->sequence_new(
        $tracer->symbol_by_name('single_quoted_char_seq'),
        $tracer->symbol_by_name('single_quoted_char'),
        { min => 0 }
    );
    $tracer->rule_new('atom ::= self');
    $sixish_grammar->rule_new( $tracer->symbol_by_name('self'),
        [ map { $char_to_symbol{$_} } split //xms, '<~~>' ] );
    $tracer->rule_new('quantifier ::= star');

    $sixish_grammar->start_symbol_set( $tracer->symbol_by_name('start'), );
    $sixish_grammar->precompute();
    return $tracer, $sixish_grammar, \%char_to_symbol, \@regex_to_symbol;
} ## end sub sixish_new

1;
