#!perl

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

