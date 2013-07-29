# Copyright 2013 Jeffrey Kegler
# This file is part of Marpa::R2.  Marpa::R2 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R2.  If not, see
# http://www.gnu.org/licenses/.

package Marpa::R2::Internal;

use 5.010;
use strict;
use warnings;
use Carp;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.065_002';
$STRING_VERSION = $VERSION;
## no critic (BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

$Carp::Internal{ 'Marpa::R2' } = 1;

sub Marpa::R2::exception {
    my $exception = join q{}, @_;
    $exception =~ s/ \n* \z /\n/xms;
    die($exception) if $Marpa::R2::JUST_DIE;
    CALLER: for ( my $i = 0; 1; $i++) {
        my ($package ) = caller($i);
	last CALLER if not $package;
	last CALLER if not 'Marpa::R2::' eq substr $package, 0, 11;
	$Carp::Internal{ $package } = 1;
    }
    Carp::croak($exception, q{Marpa::R2 exception});
}

sub Marpa::R2::offset {
    my (@desc) = @_;
    my @fields = ();
    for my $desc (@desc) {
        push @fields, split q{ }, $desc;
    }
    my $pkg        = caller;
    my $prefix     = $pkg . q{::};
    my $offset     = -1;
    my $in_comment = 0;

    no strict 'refs';
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

        Marpa::R2::exception("Unacceptable field name: $field")
            if $field =~ /[^A-Z0-9_]/xms;
        local *Marpa::R2::Internal::_temp:: = $prefix;

        package Marpa::R2::Internal::_temp;
        no warnings;
        constant->import( $field => $offset );

    } ## end for my $field (@fields)
    return 1;
} ## end sub Marpa::R2::offset

1;
