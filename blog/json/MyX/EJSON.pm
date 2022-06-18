# Copyright 2022 Jeffrey Kegler
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

package MyX::EJSON;

use 5.010;
use strict;
use warnings;

use MarpaX::ESLIF;

sub new {

    # my $eslif = MarpaX::ESLIF->new($log);
    my $eslif = MarpaX::ESLIF->new();

    # isa_ok($eslif, 'MarpaX::ESLIF');

    # $log->info('Creating JSON native grammar');
    my $eslifJson = MarpaX::ESLIF::JSON->new( $eslif, 0 );
    return $eslifJson;
}

sub doparse {
    my ($self, $inputs, $recursionLevel) = @_;
    my $rc;

    # $log->infof('Input: %s', $inputs);
    my $value = $self->decode($inputs);
    if (! defined($value)) {
        die("Failure with decode:\n$inputs\n");
    }
    # $log->infof('Decoded: %s', $value);
    #
    # Re-encode
    #
    # my $string = $eslifJson->encode($value);
    # $log->infof('Re-encoded: %s', $string);

    $rc = 1;
    goto done;

  err:
    $rc = 0;

  done:
    return $rc;
}
1;
