use 5.010;
use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

use Carp::Always; # force stack trace

use Marpa::R2 2.090; # for parse()

my $g = Marpa::R2::Scanless::G->new( { source => \(<<'END_OF_SOURCE'),

    :default ::= action => [ name, value]
    lexeme default = action => [ name, value ] latm => 1

        Expr ::=
              Number
           | Expr '**' Expr
           | Expr '-' Expr

        Number ~ [\d]+

    :discard ~ whitespace
    whitespace ~ [\s]+

END_OF_SOURCE
} );

my $input = <<EOI;
2**7-3**10
EOI

my $r = Marpa::R2::Scanless::R->new( { grammar => $g } );
$r->read(\$input);

if ( my $ambiguous_status = $r->ambiguous() ) {
    warn "# Output of ambiguous():\n", $ambiguous_status;
}

warn "\n# Output of Dumper value():";
$r->series_restart();
while (my $value_ref = $r->value()){
    warn Dumper ${ $value_ref };
}

if ( $r->ambiguity_metric() > 1 ){
    warn "\n# Output of asf->traverse():";
    $r->series_restart();
    my $asf = Marpa::R2::ASF->new( { slr => $r } );
    my $full_result = $asf->traverse( {}, \&full_traverser );
    say $full_result;
}

sub full_traverser {

    # This routine converts the glade into a list of elements.  It is called recursively.
    my ($glade, $scratch)     = @_;
    my $rule_id     = $glade->rule_id();
    my $symbol_id   = $glade->symbol_id();
    my $symbol_name = $g->symbol_name($symbol_id);

    # A token is a single choice, and we know enough to return it
    if ( not defined $rule_id ) {
        my $literal = $glade->literal();
        return ["($literal)"];
    } ## end if ( not defined $rule_id )

    # Our result will be a list of choices
    my @return_value = ();

    CHOICE: while (1) {

        # The results at each position are a list of choices, so
        # to produce a new result list, we need to take a Cartesian
        # product of all the choices
        my $length = $glade->rh_length();
        my @results = ( [] );
        for my $rh_ix ( 0 .. $length - 1 ) {
            my @new_results = ();
            for my $old_result (@results) {
                my $child_value = $glade->rh_value($rh_ix);
                for my $new_value ( @{ $child_value } ) {
                    push @new_results, [ @{$old_result}, $new_value ];
                }
            }
            @results = @new_results;
        } ## end for my $rh_ix ( 0 .. $length - 1 )

        # Special case for the start rule
        if ( $symbol_name eq '[:start]' ) {
            return [ map { join q{}, @{$_} } @results ];
        }

        # Now we have a list of choices, as a list of lists.  Each sub list
        # is a list of elements, which we need to join into
        # a single element.  The result will be to collapse
        # one level of lists, and leave us with a list of
        # elements
        my $join_ws = q{ };
        $join_ws = qq{\n   } if $symbol_name eq 'S';
        push @return_value,
            map { '(' . $symbol_name . q{ } . ( join $join_ws, @{$_} ) . ')' }
            @results;

        # Look at the next alternative in this glade, or end the
        # loop if there is none
        last CHOICE if not defined $glade->next();

    } ## end CHOICE: while (1)

    # Return the list of elements for this glade
    return \@return_value;
} ## end sub full_traverser
