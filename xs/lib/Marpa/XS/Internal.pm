# Copyright 2011 Jeffrey Kegler
# This file is part of Marpa::XS.  Marpa::XS is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::XS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::XS.  If not, see
# http://www.gnu.org/licenses/.

package Marpa::XS::Internal;

use 5.010;
use strict;
use warnings;
use integer;
use Carp;

*Marpa::exception = \&Carp::croak;

## no critic (Subroutines::RequireArgUnpacking)
sub Marpa::XS::internal_error {
    Carp::confess(
        "Internal Marpa::XS Error: This could be a bug in Marpa::XS\n", @_ );
}
## use critic

# Perl critic at present is not smart about underscores
# in hex numbers
## no critic (ValuesAndExpressions::RequireNumberSeparators)
use constant N_FORMAT_MASK     => 0xffff_ffff;
use constant N_FORMAT_HIGH_BIT => 0x8000_0000;
## use critic

# Also used as mask, so must be 2**n-1
# Perl critic at present is not smart about underscores
# in hex numbers
use constant N_FORMAT_MAX => 0x7fff_ffff;

sub Marpa::offset {
    my (@desc)   = @_;
    my @fields = ();
    for my $desc (@desc) {
        push @fields, split ' ', $desc;
    }
    my $pkg        = caller;
    my $prefix     = $pkg . q{::};
    my $offset     = -1;
    my $in_comment = 0;

    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    no strict 'refs';
    ## use critic
    FIELD: for my $field (@fields) {

        if ($in_comment) {
            $in_comment = $field ne ':}' && $field ne '}';
            next FIELD;
        }

        PROCESS_OPTION: {
            last PROCESS_OPTION if $field !~ /\A [{:] /xms;
            if ( $field =~ / \A [:] package [=] (.*) /xms ) {
                $prefix = $1 . q{::};
                next FIELD;
            }
            if ( $field =~ / \A [:]? [{] /xms ) {
                $in_comment++;
                next FIELD;
            }
        } ## end PROCESS_OPTION:

        if ( $field !~ s/\A=//xms ) {
            $offset++;
        }

        if ( $field =~ / \A ( [^=]* ) = ( [0-9+-]* ) \z/xms ) {
            $field  = $1;
            $offset = $2 + 0;
        }

        Marpa::exception("Unacceptable field name: $field")
            if $field =~ /[^A-Z0-9_]/xms;
        my $field_name = $prefix . $field;
        *{$field_name} = sub () {$offset};
    } ## end for my $field (@fields)
    return 1;
} ## end sub Marpa::offset

1;
