package Marpa::R2::Demo::Sixish1;

use 5.010;
use strict;
use warnings;

use Marpa::R2;

{
    my $file = './OP4.pm';
    unless ( my $return = do $file ) {
        warn "couldn't parse $file: $@" if $@;
        warn "couldn't do $file: $!" unless defined $return;
        warn "couldn't run $file" unless $return;
    }
}

{

    my $rules =
    Marpa::R2::Demo::OP4::parse_rules( <<'END_OF_RULES');
    <start> ::= <concatenation>
    <concatenation> ::=
        <concatenation> ::= <concatenation> <opt_ws> <quantified_atom>
    <opt_ws> ::=
    <opt_ws> ::= <opt_ws> <ws_char>
    <quantified_atom> ::= <atom> <opt_ws> <quantifier>
    <quantified_atom> ::= <atom>
    <atom> ::= <quoted_literal>
        <quoted_literal> ::= <single_quote> <single_quoted_char_seq> <single_quote>
    <single_quoted_char_seq> ::= <single_quoted_char>*
    <atom> ::= <self>
    <self> ::= '<~~>'
    <quantifier> ::= <star>
END_OF_RULES

require Data::Dumper; say Data::Dumper::Dumper($rules);
}

sub rule_by_name {
   my ($self, $name) = @_;
   my $rule = $self->{rule_by_name}->{$name};
   die qq{No rule with name "$name"} if not defined $rule;
   return $rule;
}

sub rule_name {
   my ($self, $rule_id) = @_;
   my $rule_name = $self->{rule_name}->[$rule_id];
   $rule_name = 'R' . $rule_id if not defined $rule_name;
   return $rule_name;
}

sub rule_name_set {
   my ($self, $name, $rule_id) = @_;
   $self->{rule_name}->[$rule_id] = $name;
   $self->{rule_by_name}->{$name} = $rule_id;
   return $rule_id;
}

sub rule_new {
    my ( $self, $ebnf ) = @_;
    my ( $lhs, $rhs ) = split /\s*[:][:][=]\s*/xms, $ebnf;
    die "Malformed EBNF: $ebnf" if not defined $lhs;
    $lhs =~ s/\A\s*//xms;
    $lhs =~ s/\s*\z//xms;
    my @rhs = split /\s+/xms, $rhs;
    return $self->{grammar}->rule_new( $self->symbol_by_name($lhs),
        [ map { $self->symbol_by_name($_) } @rhs ] );
} ## end sub rule_new

sub symbol_by_name {
   my ($self, $name) = @_;
   my $symbol = $self->{symbol_by_name}->{$name};
   die qq{No symbol with name "$name"} if not defined $symbol;
   return $symbol;
}

sub symbol_name {
   my ($self, $symbol_id) = @_;
   my $symbol_name = $self->{symbol_name}->[$symbol_id];
   $symbol_name = 'R' . $symbol_id if not defined $symbol_name;
   return $symbol_name;
}

sub symbol_name_set {
   my ($self, $name, $symbol_id) = @_;
   $self->{symbol_name}->[$symbol_id] = $name;
   $self->{symbol_by_name}->{$name} = $symbol_id;
   return $symbol_id;
}

sub symbol_new {
   my ($self, $name) = @_;
   return $self->symbol_name_set($name, $self->{grammar}->symbol_new());
}

sub dotted_rule {
    my ( $self, $rule_id, $dot_position ) = @_;
    my $grammar     = $self->{grammar};
    my $rule_length = $grammar->rule_length($rule_id);
    $dot_position = $rule_length if $dot_position < 0;
    my $lhs         = $self->symbol_name( $grammar->rule_lhs($rule_id) );
    my @rhs =
        map { $self->symbol_name( $grammar->rule_rhs( $rule_id, $_ ) ) }
        ( 0 .. $rule_length - 1 );
    $dot_position = 0 if $dot_position < 0;
    splice( @rhs, $dot_position, 0, q{.} );
    return join q{ }, $lhs, q{::=}, @rhs;
} ## end sub dotted_rule

sub progress_report {
    my ( $self, $recce, $ordinal ) = @_;
    my $result = q{};
    $ordinal //= $recce->latest_earley_set();
    $recce->progress_report_start($ordinal);
    ITEM: while (1) {
        my ( $rule_id, $dot_position, $origin ) = $recce->progress_item();
        last ITEM if not defined $rule_id; 
        $result
            .= q{@}
            . $origin . q{: }
            . $self->dotted_rule( $rule_id, $dot_position ) . "\n";
    } ## end ITEM: while (1)
    $recce->progress_report_finish();
    return $result;
} ## end sub progress_report

sub new {
    my ($class) = @_;
    my $sixish_grammar  = Marpa::R2::Thin::G->new( { if => 1 } );
    my %char_to_symbol  = ();
    my @regex_to_symbol = ();

    my $self = bless {}, $class;
    $self->{grammar} = $sixish_grammar;
    $self->{rule_by_name} = {};
    $self->{symbol_by_name} = {};
    $self->{rule_names} = {};
    $self->{symbol_names} = {};

    $char_to_symbol{'*'}  = $self->symbol_new('star');
    $char_to_symbol{'<'}  = $self->symbol_new('langle');
    $char_to_symbol{'>'}  = $self->symbol_new('rangle');
    $char_to_symbol{q{'}} = $self->symbol_new('single_quote');
    $char_to_symbol{'~'}  = $self->symbol_new('tilde');

    my $s_ws_char = $self->symbol_new('ws_char');
    push @regex_to_symbol, [ qr/\s/xms, $s_ws_char ];
    my $s_single_quoted_char = $self->symbol_new('single_quoted_char');
    push @regex_to_symbol, [ qr/[^\\']/xms, $s_single_quoted_char ];

    $self->symbol_new('atom');
    $self->symbol_new('concatenation');
    $self->symbol_new('single_quoted_char_seq');
    $self->symbol_new('opt_ws');
    $self->symbol_new('quantified_atom');
    $self->symbol_new('quantifier');
    $self->symbol_new('quoted_literal');
    $self->symbol_new('self');
    $self->symbol_new('start');

    $self->rule_new('start ::= concatenation');
    $self->rule_new('concatenation ::=');
    $self->rule_new(
        'concatenation ::= concatenation opt_ws quantified_atom');
    $self->rule_new('opt_ws ::= ');
    $self->rule_new('opt_ws ::= opt_ws ws_char');
    $self->rule_new('quantified_atom ::= atom opt_ws quantifier');
    $self->rule_new('quantified_atom ::= atom');
    $self->rule_new('atom ::= quoted_literal');
    $self->rule_new(
        'quoted_literal ::= single_quote single_quoted_char_seq single_quote');
    $sixish_grammar->sequence_new(
        $self->symbol_by_name('single_quoted_char_seq'),
        $self->symbol_by_name('single_quoted_char'),
        { min => 0 }
    );
    $self->rule_new('atom ::= self');
    $sixish_grammar->rule_new( $self->symbol_by_name('self'),
        [ map { $char_to_symbol{$_} } split //xms, '<~~>' ] );
    $self->rule_new('quantifier ::= star');

    $sixish_grammar->start_symbol_set( $self->symbol_by_name('start'), );
    $sixish_grammar->precompute();

        $self->{grammar}         = $sixish_grammar;
        $self->{char_to_symbol}  = \%char_to_symbol;
        $self->{regex_to_symbol} = \@regex_to_symbol;
    return $self;
} ## end sub sixish_new

1;
