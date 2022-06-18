#!perl
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

use Marpa::R2::HTML qw(html);

use 5.010;
use strict;
use warnings;

my $answer = html(
    ( \join q{}, <DATA> ),
    {   td => sub { return Marpa::R2::HTML::contents() },
        a  => sub {
            my $href = Marpa::R2::HTML::attributes()->{href};
            return undef if not defined $href;
            return [ link => $href ];
        },
        'td.c' => sub {
            my @values = @{ Marpa::R2::HTML::values() };
            if ( ref $values[0] eq 'ARRAY' ) { return $values[0] }
            return [ test => 'OK' ] if Marpa::R2::HTML::contents eq 'ABC';
            return [ test => 'OK' ] if Marpa::R2::HTML::contents eq 'DEF';
            return [ test => '' ];
        },
        tr => sub {
            my @cells = @{ Marpa::R2::HTML::values() };
            return undef if shift @cells != 5;
            return undef if shift @cells != 1;
            my $ok = 0;
            my $link;
            for my $cell (@cells) {
                my ( $type, $value ) = @{$cell};
                $ok = 1 if $type eq 'test' and $value eq 'OK';
                $link = $value if $type eq 'link';
            }
            return $link if $ok;
            return undef;
        },
        ':TOP' => sub { return Marpa::R2::HTML::values(); }
    }
);

die "No parse" if not defined $answer;
say join "\n", @{$answer};

__DATA__
<table>
    <tbody>

        <tr class="epeven completed">
            <td>5</td>
            <td>1</td>
            <td class="c">ABC</td>
            <td class="c">satus</td>
            <td class="c"><a href="/path/link">Download</a></td>
        </tr>
        <tr class="epeven completed">
            <td>5</td>
            <td>1</td>
            <td class="c">status</td>
            <td class="c">DEF</td>
            <td class="c"><a href="/path2/link">Download</a></td>
        </tr>


    </table>

