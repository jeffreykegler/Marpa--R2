#!perl

# A quick utility to spot overlong lines.
# Earlier versions of Cweb reject these, so we clean them up to be
# compatible.

use strict;
use warnings;
use English '-no_match_vars';

while ( my $line = <STDIN> ) {
    print "Line #$NR ", length $line, " ", $line if length $line > 90;
}
