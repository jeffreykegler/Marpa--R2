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

use 5.010001;
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More;

BEGIN {
    use lib 'html/tool/lib';
    my $eval_result = eval { require Marpa::R2::HTML::Test::Util; 1 };
    if ( !$eval_result ) {
        Test::More::plan tests => 1;
        Test::More::fail(
            "Could not load Marpa::R2::HTML::Test::Util; $EVAL_ERROR");
        exit 0;
    } ## end if ( !$eval_result )
} ## end BEGIN

BEGIN { Marpa::R2::HTML::Test::Util::load_or_skip_all('HTML::Parser'); }
BEGIN { Marpa::R2::HTML::Test::Util::load_or_skip_all('HTML::Entities'); }

# These tests are based closely on those in the HTML-Tree module,
# the authors of which I gratefully acknowledge.

Test::More::plan tests => 40;
my $DEBUG = 2;

use Marpa::R2::HTML;

my $html_args = {
    ':CRUFT' => sub {
        my $literal = Marpa::R2::HTML::literal();
        say {*STDERR} 'Cruft: ', $literal
            or Carp::croak("Cannot print: $ERRNO");
        return qq{<CRUFT literal="$literal">};
    },
    ':PCDATA' => sub {
        my $literal = Marpa::R2::HTML::literal();
        if ( defined &HTML::Entities::decode_entities ) {
            $literal =
                HTML::Entities::encode_entities(
                HTML::Entities::decode_entities($literal) );
        }
        return $literal;
    },
    ':PROLOG' => sub {
        my $literal = Marpa::R2::HTML::literal();
        $literal =~ s/\A [\x{20}\t\f\x{200B}]+ //xms;
        $literal =~ s/ [\x{20}\t\f\x{200B}]+ \z//xms;
        return $literal;
    },
    ':COMMENT' => sub { return q{} },
    q{*}       => sub {
        my $tagname = Marpa::R2::HTML::tagname();

        # say STDERR "In handler for $tagname element";

        Carp::croak('Not in an element') if not $tagname;
        my $attributes = Marpa::R2::HTML::attributes();

        # Note this logic suffices to get through
        # the test set but it does not handle
        # the necessary escaping for a production
        # version
        my $start_tag = "<$tagname";
        for my $attribute ( sort keys %{$attributes} ) {
            $start_tag
                .= qq{ $attribute="} . $attributes->{$attribute} . q{"};
        }
        $start_tag .= '>';
        my $end_tag = "</$tagname>";

        my $descendant_data =

# Marpa::R2::Display
# name: dataspec example

            Marpa::R2::HTML::descendants('token_type,literal,element')

# Marpa::R2::Display::End

            ;    # semi to end $descendant_data definition

        # For UL element, eliminate all but the LI element children
        if ( $tagname eq 'ul' ) {
            $descendant_data =
                [ grep { defined $_->[2] and $_->[2] eq 'li' }
                    @{$descendant_data} ];
        }

        my @contents = ();
        DATUM: for my $descendant_datum (@{$descendant_data}) {
            my $token_type = $descendant_datum->[0];
            if ( not defined $token_type ) {
                push @contents, $descendant_datum->[1];
                next DATUM;
            }
            next DATUM if $token_type eq 'S';
            next DATUM if $token_type eq 'E';
            push @contents, $descendant_datum->[1];
        } ## end for my $descendant_datum (@descendant_data)
        my $contents = join q{}, @contents;
        $contents =~ s/\A [\x{20}\t\f\x{200B}]+ //xms;
        $contents =~ s/ [\x{20}\t\f\x{200B}]+ \z//xms;
        return join q{}, $start_tag, $contents, $end_tag;
    },
};

Test::More::ok 1;

Test::More::ok same(
    '<title>foo</title><p>I like pie',
    '<html><head><title>foo</title></head><body><p>I like pie</p></body></html>'
);

Test::More::ok !same( 'x'   => 'y', 1 );
Test::More::ok !same( '<p>' => 'y', 1 );

Test::More::ok same( q{} => q{} );
Test::More::ok same( q{} => q{ } );
Test::More::ok same( q{} => q{  } );

Test::More::ok same( q{} => '<!-- tra la la -->' );
Test::More::ok same( q{} => '<!-- tra la la --><!-- foo -->' );

Test::More::ok same( q{} => \'<head></head><body></body>' );

Test::More::ok same( '<head>' => q{} );

Test::More::ok same( '<head></head><body>' => \'<head></head><body></body>' );

Test::More::ok same(
    '<img alt="456" src="123">' => '<img src="123" alt="456">' );
Test::More::ok same(
    '<img alt="456" src="123">' => '<img src="123"    alt="456">' );
Test::More::ok same(
    '<img alt="456" src="123">' => '<img src="123"    alt="456"   >' );

Test::More::ok !same(
    '<img alt="456" >' => '<img src="123"    alt="456"   >',
    1
);

SKIP: {
    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    defined &HTML::Entities::decode_entities
        or Test::More::skip 'HTML::Entities not installed', 6;
    ## use critic

    Test::More::ok same( 'abc&#32;xyz'  => 'abc xyz' );
    Test::More::ok same( 'abc&#x20;xyz' => 'abc xyz' );

    Test::More::ok same( 'abc&#43;xyz'  => 'abc+xyz' );
    Test::More::ok same( 'abc&#x2b;xyz' => 'abc+xyz' );

    Test::More::ok same( '&#97;bc+xyz'  => 'abc+xyz' );
    Test::More::ok same( '&#x61;bc+xyz' => 'abc+xyz' );

} ## end SKIP:

# Now some list tests.

Test::More::ok same( '<ul><li>x</ul>after' => '<ul><li>x</li></ul>after' );
Test::More::ok same(
    '<ul><li>x<li>y</ul>after' => '<ul><li>x</li><li>y</li></ul>after' );

Test::More::ok same( '<ul> <li>x</li> <li>y</li> </ul>after' =>
        '<ul><li>x</li><li>y</li></ul>after' );

Test::More::ok same( '<ul><li>x<li>y</ul>after' => \
        '<head></head><body><ul><li>x</li><li>y</li></ul>after</body>' );

# Now some table tests.

Test::More::ok same( '<table>x<td>y<td>z' =>
        '<table><tr><td>x</td><td>y</td><td>z</td></table>' );

Test::More::ok same( '<table>x<td>y<tr>z' =>
        '<table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>' );

Test::More::ok same(
    '<table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>' =>
        '<table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>' );
Test::More::ok same(
    '<table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>' => \
        '<head></head><body><table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>'
);

Test::More::ok same( '<table>x' => '<td>x' );
Test::More::ok same( '<table>x' => '<table><td>x' );
Test::More::ok same( '<table>x' => '<tr>x' );
Test::More::ok same( '<table>x' => '<tr><td>x' );
Test::More::ok same( '<table>x' => '<table><tr>x' );
Test::More::ok same( '<table>x' => '<table><tr><td>x' );

# Now some p tests.

Test::More::ok same( '<p>x<p>y<p>z' => '<p>x</p><p>y</p><p>z' );
Test::More::ok same( '<p>x<p>y<p>z' => '<p>x</p><p>y<p>z</p>' );
Test::More::ok same( '<p>x<p>y<p>z' => '<p>x</p><p>y</p><p>z</p>' );
Test::More::ok same(
    '<p>x<p>y<p>z' => \'<head></head><body><p>x</p><p>y</p><p>z</p>' );

sub same {
    my ( $code1, $code2, $flip ) = @_;

    if ( ref $code1 ) { $code1 = ${$code1} }
    if ( ref $code2 ) { $code2 = ${$code2} }

    my $value1;
    if (not eval { $value1 = Marpa::R2::HTML::html( \$code1, $html_args ); 1 }
        )
    {
        say "No parse for $code1; $EVAL_ERROR"
            or Carp::croak("Cannot print: $ERRNO");
        return $flip;
    } ## end if ( not eval { $value1 = Marpa::R2::HTML::html( \$code1...)})

    my $value2;
    if (not eval { $value2 = Marpa::R2::HTML::html( \$code2, $html_args ); 1 }
        )
    {
        say "No parse for $code2; $EVAL_ERROR"
            or Carp::croak("Cannot print: $ERRNO");
        return $flip;
    } ## end if ( not eval { $value2 = Marpa::R2::HTML::html( \$code2...)})

    my $out1 = ${$value1};
    my $out2 = ${$value2};

    my $rv = ( $out1 eq $out2 );

    if ( $flip ? ( !$rv ) : $rv ) {
        if ( $DEBUG > 2 ) {
            print
                "In1 $code1\n",
                "In2 $code2\n", "Out1 $out1\n", "Out2 $out2\n", "\n\n"
                or Carp::croak("Cannot print: $ERRNO");
        } ## end if ( $DEBUG > 2 )
    } ## end if ( $flip ? ( !$rv ) : $rv )
    else {
        print '# The following failure is at ' . join( ' : ', caller ), "\n",
              '# Explanation of failure: '
            . ( $flip ? 'same' : 'different' )
            . ' parse trees!', "\n",
            '# Input code 1:',           $code1, "\n",
            '# Input code 2:',           $code2, "\n",
            '# Output tree (as XML) 1:', $out1,  "\n",
            '# Output tree (as XML) 2:', $out2,  "\n",
            or Carp::croak("Cannot print: $ERRNO");
    } ## end else [ if ( $flip ? ( !$rv ) : $rv ) ]

    return $rv;
} ## end sub same

# vim: set expandtab shiftwidth=4:
