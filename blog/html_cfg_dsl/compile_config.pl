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

# Order matters !!
my @terminals = (
    [ const_CDATA => qr/CDATA\b/xms ],
    [ const_PCDATA => qr/PCDATA\b/xms ],
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
is_included_statement ::= element kw_is kw_included kw_in group
    action => do_is_included_statement
element ::= start_tag
is_a_included_statement ::= element kw_is kw_a flow kw_included kw_in group
    action => do_is_a_included_statement
is_statement ::= element kw_is flow
    action => do_is_statement
contains_statement ::= element kw_contains contents
    action => do_contains_statement
contents = content_item*
content_item = element | group | kw_PCDATA | kw_CDATA
ruby_statement ::= ruby_symbol ruby_op ruby_candidates
ruby_symbol_list ::= ruby_symbol+
ruby_symbol ::= kw_PCDATA | kw_CDATA
  | start_tag | start_group_wildcard | start_wildcard
  | end_tag | end_group_wildcard | end_wildcard
END_OF_GRAMMAR
 
    my $grammar = Marpa::R2::Grammar->new(
       { start => 'configuration',
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
    my $length = length $string;
    pos $string = 0;
    TOKEN: while ( pos $string < $length ) {

        # skip comment
        next TOKEN if $string =~ m/\G [#] [^\n]* \n/gcxms;

        # skip whitespace
        next TOKEN if $string =~ m/\G\s+/gcxms;

        # read other tokens
        TOKEN_TYPE: for my $t (@terminals) {
            next TOKEN_TYPE if not $string =~ m/\G($t->[1])/gcxms;
	    say join " ", $t->[0], '->', $1;
            # if ( not defined $rec->read( $t->[0], $1 ) ) {
                # die_on_read_problem( $rec, $t, $1, $string, pos $string );
            # }
            next TOKEN;
        } ## end TOKEN_TYPE: for my $t (@terminals)

        die q{No token at "}, ( substr $string, pos $string, 40 ),
            q{", position }, pos $string;
    } ## end TOKEN: while ( pos $string < $length )

} ## end sub calculate

my $source = join q{}, <>;
compile($source);

