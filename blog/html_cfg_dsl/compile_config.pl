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

sub compile {
    my ($string) = @_;

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

