#!perl

# This calculator contains *TWO* DSL's.
# The first one is for the calculator itself.
# The calculator's grammar is written in OP2.
# OP2 is the second DSL, and its code is the
# second half of this file.

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );

use Getopt::Long;
use Marpa::R2;

# my $do_demo = 0;
# my $getopt_result = GetOptions( "demo!" => \$do_demo, );

sub usage {
    die <<"END_OF_USAGE_MESSAGE";
$PROGRAM_NAME < configuration_file
$PROGRAM_NAME configuration_file
END_OF_USAGE_MESSAGE
} ## end sub usage

# if ( not $getopt_result ) {
    # usage();
# }
# if ($do_demo) {
    # if ( scalar @ARGV > 0 ) { say join " ", @ARGV; usage(); }
# }
# elsif ( scalar @ARGV <= 0 ) { usage(); }

sub die_on_read_problem {
    my ( $rec, $t, $token_value, $string, $position ) = @_;
    say $rec->show_progress() or die "say failed: $ERRNO";
    my $problem_position = $position - length $1;
    my $before_start     = $problem_position - 40;
    $before_start = 0 if $before_start < 0;
    my $before_length = $problem_position - $before_start;
    die "Problem near position $problem_position\n",
        q{Problem is here: "},
        ( substr $string, $before_start, $before_length + 40 ),
        qq{"\n},
        ( q{ } x ( $before_length + 18 ) ), qq{^\n},
        q{Token rejected, "}, $t->[0], qq{", "$token_value"},
        ;
} ## end sub die_on_read_problem

sub do_what_I_mean {

    # The first argument is the per-parse variable.
    # At this stage, just throw it away
    shift;

    # Throw away any undef's
    my @children = grep { defined } @_;

    # Return what's left
    return scalar @children > 1 ? \@children : shift @children;
}

# Order matters !!
my @terminals = (
    [ kw_CDATA => qr/CDATA\b/xms ],
    [ kw_PCDATA => qr/PCDATA\b/xms ],
    [ kw_is => qr/is\b/ixms ],
    [ kw_a => qr/a\b/ixms ],
    [ kw_contains => qr/contains\b/ixms ],
    [ kw_included => qr/included\b/ixms ],
    [ kw_in => qr/in\b/ixms ],
    [ flow => qr/[*]\w+\b/xms ],
    [ group => qr/[%]\w+\b/xms ],
    [ list => qr/[@]\w+\b/xms ],
    [ start_tag => qr/[<]\w+[>]/xms ],
    [ start_tag => qr{[<][/]\w+[>]}xms ],
    [ wildcard_start_tag => qr/[<][*][>]/xms ],
    [ wildcard_end_tag => qr{[<][/][*][>]}xms ],
    [ group_start_tag => qr/[<][%]\w+[>]/xms ],
    [ op_assign =>     qr/[=]/xms ],
    [ op_ruby   =>   qr/[-][>]/xms ],
    [ semi_colon   =>   qr/[;]/xms ],
);

sub create_grammar {

my $source = <<'END_OF_GRAMMAR';
translation_unit ::= statement*
statement ::= is_included_statement
    | is_a_included_statement
    | is_statement
    | contains_statement
    | list_assignment
    | ruby_statement
is_included_statement ::= element kw_is kw_included kw_in <group>
    # action => do_is_included_statement
element ::= start_tag
is_a_included_statement ::= element kw_is kw_a flow kw_included kw_in <group>
    # action => do_is_a_included_statement
is_statement ::= element kw_is flow
    # action => do_is_statement
contains_statement ::= element kw_contains contents
    # action => do_contains_statement
contents ::= content_item*
list_assignment ::= list op_assign list_members
list_members ::= list_member*
list_member ::= ruby_symbol
list_member ::= list
content_item ::= element | <group> | kw_PCDATA | kw_CDATA
ruby_statement ::= ruby_symbol op_ruby ruby_symbol_list
ruby_symbol_list ::= ruby_symbol*
ruby_symbol ::= kw_PCDATA | kw_CDATA
  | start_tag | group_start_tag | wildcard_start_tag
  | end_tag | group_end_tag | wildcard_end_tag
  | list
END_OF_GRAMMAR
 
    my $grammar = Marpa::R2::Grammar->new(
       { start => 'translation_unit',
       actions => __PACKAGE__,
       rules =>[$source],
       default_action => 'main::do_what_I_mean'
       }
    );
    $grammar->precompute();
   return $grammar;
}

sub compile {
    my ($string) = @_;

    state $grammar = create_grammar();
    my $recce = Marpa::R2::Recognizer->new({ grammar => $grammar});
    my $length = length $string;
    pos $string = 0;
    TOKEN: while ( pos $string < $length ) {

        # skip comment
        next TOKEN if $string =~ m/\G \s* [#] [^\n]* \n/gcxms;

        # skip whitespace
        next TOKEN if $string =~ m/\G\s+/gcxms;

        # read other tokens
        TOKEN_TYPE: for my $t (@terminals) {
            next TOKEN_TYPE if not $string =~ m/\G($t->[1])/gcxms;
	    say join " ", $t->[0], '->', $1;
            if ( not defined $recce->read( $t->[0], $1 ) ) {
                die_on_read_problem( $recce, $t, $1, $string, pos $string );
            }
            next TOKEN;
        } ## end TOKEN_TYPE: for my $t (@terminals)

        die q{No token at "}, ( substr $string, pos $string, 40 ),
            q{", position }, pos $string;
    } ## end TOKEN: while ( pos $string < $length )

    my $value_ref = $recce->value();
    require Data::Dumper; say Data::Dumper::Dumper($value_ref);

} ## end sub calculate

my $source = join q{}, <>;
compile($source);

