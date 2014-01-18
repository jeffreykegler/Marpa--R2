#!/usr/bin/perl -w
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

use 5.010;
use strict;
use warnings;

use charnames ':full';
use Scalar::Util;
use Data::Dumper ();
use English qw( -no_match_vars );
use Test::More ();
use lib 'pperl';

BEGIN {
    my $PPI_problem;
    CHECK_PPI: {
        if ( not eval { require PPI } ) {
            $PPI_problem = "PPI not installed: $EVAL_ERROR";
            last CHECK_PPI;
        }
        if ( not PPI->VERSION(1.206) ) {
            $PPI_problem = 'PPI 1.206 not installed';
        }
    } ## end CHECK_PPI:
    if ($PPI_problem) {
        Test::More::plan skip_all => $PPI_problem;
    }
    else {
        Test::More::plan tests => 12;
    }
} ## end BEGIN

use Marpa::R2;
use Marpa::R2::Perl;

our @OUTPUT = ();
our %SYMTAB = ( SCALAR => {} );

sub DEBUG_dump {
    say {*STDERR} 'DEBUG: ', join "\n", @main::OUTPUT
        or die "Cannot print to STDERR: $ERRNO";
    say {*STDERR} 'DEBUG: Symbol table: ', Data::Dumper::Dumper( \%SYMTAB )
        or die "Cannot print to STDERR: $ERRNO";
    return;
} ## end sub DEBUG_dump

# This code is about Perl GRAMMAR.
# If you're writing
# a Perl SEMANTICS, and looking for a place to start,
# you probably don't want to start here.
# The purpose of these semantics is to test the grammar -- no more.
# They are probably good for nothing else.
#
# Here are some of the defects:
#
# 1.  Not a 'safe' evaluator for code from untrusted sources.
#    'eval' is used to interpret the string constants.
#
# 2.  Most Perl semantics is not implementation and where
#     the implementation exists it often is at the toy level.
#     Basically, anything not needed to interpret
#     Data::Dumper output is ignored.
#
# 3.  No optimization.  It's fast enough for a test suite.
#
# 4.  Etc., etc., etc.  You get the idea.

sub coerce_to_R {
    my ($tagged) = @_;
    my ( $side, $v ) = @{$tagged};
    return $side eq 'R' ? $v : ${$v};
}

sub do_term_lstop {
    my ( undef, $lstop, $list_tagged ) = @_;
    die "Unimplemented lstop: $lstop" if $lstop ne 'bless';
    my $list_ref = coerce_to_R($list_tagged);
    return [ 'L', \\( bless $list_ref->[0], $list_ref->[1] ) ];
} ## end sub do_term_lstop

# term_hi : term_hi ARROW '{' expr ';' '}' ; term_hi__arrow_hash /* somehref->{bar();} */
sub do_term_hi__arrow_hash {
    my ( undef, $term, undef, undef, $element ) = @_;

    my $element_ref      = coerce_to_R($element);
    my $element_ref_type = Scalar::Util::reftype $element_ref;
    die "element in term->[element] is not an scalar: $element_ref_type"
        if $element_ref_type ne 'SCALAR';

    my ( $term_side, $term_ref ) = @{$term};
    if ( $term_side eq 'L' ) {
        $term_ref = ${$term_ref};
    }
    if (   ( my $ref_type = Scalar::Util::reftype $term_ref) ne 'REF'
        or ( my $ref_ref_type = Scalar::Util::reftype ${$term_ref} ) ne
        'HASH' )
    {
        my $type = $ref_type eq 'REF' ? "REF to $ref_ref_type" : $ref_type;
        die "term in term->[element] is not an array ref: it is $type";
    } ## end if ( ( my $ref_type = Scalar::Util::reftype $term_ref...))
    return [ 'L', \\( ${$term_ref}->{ ${$element_ref} } ) ];
} ## end sub do_term_hi__arrow_hash

# term_hi : term_hi ARROW '[' expr ']' ; term_hi__arrow_array /* somearef->[$element] */
sub do_term_hi__arrow_array {
    my ( undef, $term, undef, undef, $element ) = @_;

    my $element_ref      = coerce_to_R($element);
    my $element_ref_type = Scalar::Util::reftype $element_ref;
    die "element in term->[element] is not an scalar: $element_ref_type"
        if $element_ref_type ne 'SCALAR';

    my ( $term_side, $term_ref ) = @{$term};
    if ( $term_side eq 'L' ) {
        $term_ref = ${$term_ref};
    }
    if (   ( my $ref_type = Scalar::Util::reftype $term_ref) ne 'REF'
        or ( my $ref_ref_type = Scalar::Util::reftype ${$term_ref} ) ne
        'ARRAY' )
    {
        my $type = $ref_type eq 'REF' ? "REF to $ref_ref_type" : $ref_type;
        die "term in term->[element] is not an array ref: it is $type";
    } ## end if ( ( my $ref_type = Scalar::Util::reftype $term_ref...))
    return [ 'L', \\( ${$term_ref}->[ ${$element_ref} ] ) ];
} ## end sub do_term_hi__arrow_array

# term_hi  : scalar '{' expr ';' '}' ;  hash_index /* $foo->{bar();} */
# term_hi  : term_hi '{' expr ';' '}' ; hash_index_r /* $foo->[bar]->{baz;} */
sub do_hash_index {
    my ( undef, $term, undef, $element ) = @_;

    my $element_ref      = coerce_to_R($element);
    my $element_ref_type = Scalar::Util::reftype $element_ref;
    die "element in term->[element] is not an scalar: $element_ref_type"
        if $element_ref_type ne 'SCALAR';

    my ( $term_side, $term_ref ) = @{$term};
    if ( $term_side eq 'R' ) {
        die 'rvalue term in scalar[element] not implemented';
    }
    if (   ( my $ref_type = Scalar::Util::reftype ${$term_ref} ) ne 'REF'
        or ( my $ref_ref_type = Scalar::Util::reftype ${ ${$term_ref} } ) ne
        'HASH' )
    {
        my $type = $ref_type eq 'REF' ? "REF to $ref_ref_type" : $ref_type;
        die "scalar in scalar[element] is not an hash ref: it is $type";
    } ## end if ( ( my $ref_type = Scalar::Util::reftype ${$term_ref...}))
    return [ 'L', \\( ${ ${$term_ref} }->{ ${$element_ref} } ) ];
} ## end sub do_hash_index

sub do_array_index {
    my ( undef, $term, undef, $element ) = @_;

    my $element_ref      = coerce_to_R($element);
    my $element_ref_type = Scalar::Util::reftype $element_ref;
    die "element in term->[element] is not an scalar: $element_ref_type"
        if $element_ref_type ne 'SCALAR';

    my ( $term_side, $term_ref ) = @{$term};
    if ( $term_side eq 'R' ) {
        die 'rvalue term in scalar[element] not implemented';
    }
    if (   ( my $ref_type = Scalar::Util::reftype ${$term_ref} ) ne 'REF'
        or ( my $ref_ref_type = Scalar::Util::reftype ${ ${$term_ref} } ) ne
        'ARRAY' )
    {
        my $type = $ref_type eq 'REF' ? "REF to $ref_ref_type" : $ref_type;
        die "scalar in scalar[element] is not an hash ref: it is $type";
    } ## end if ( ( my $ref_type = Scalar::Util::reftype ${$term_ref...}))
    return [ 'L', \\( ${ ${$term_ref} }->[ ${$element_ref} ] ) ];
} ## end sub do_array_index

sub do_argexpr {
    my ( undef, $argexpr, undef, $term ) = @_;
    my $argexpr_ref = coerce_to_R($argexpr);
    my @result;
    PROCESS_BY_REFTYPE: {
        my $reftype = Scalar::Util::reftype $argexpr_ref;
        if ( $reftype eq 'REF' ) {
            push @result, ${$argexpr_ref};
            last PROCESS_BY_REFTYPE;
        }
        if ( $reftype eq 'SCALAR' ) {
            push @result, ${$argexpr_ref};
            last PROCESS_BY_REFTYPE;
        }
        if ( $reftype eq 'ARRAY' ) {
            push @result, @{$argexpr_ref};
            last PROCESS_BY_REFTYPE;
        }
        if ( $reftype eq 'HASH' ) {
            push @result, %{$argexpr_ref};
            last PROCESS_BY_REFTYPE;
        }
        die "Unknown argexpr type: $_";
    } ## end PROCESS_BY_REFTYPE:
    my $term_ref = coerce_to_R($term);
    PROCESS_BY_REFTYPE: {
        my $reftype = Scalar::Util::reftype $term_ref;
        if ( $reftype eq 'REF' ) {
            push @result, ${$term_ref};
            last PROCESS_BY_REFTYPE;
        }
        if ( $reftype eq 'SCALAR' ) {
            push @result, ${$term_ref};
            last PROCESS_BY_REFTYPE;
        }
        if ( $reftype eq 'ARRAY' ) {
            push @result, @{$term_ref};
            last PROCESS_BY_REFTYPE;
        }
        if ( $reftype eq 'HASH' ) {
            push @result, %{$term_ref};
            last PROCESS_BY_REFTYPE;
        }
        die "Unknown term type: $_";
    } ## end PROCESS_BY_REFTYPE:
    return [ 'L', \\@result ];
} ## end sub do_argexpr

# scalar assignment only
sub do_assign {
    my ( undef, $lhs, undef, $rhs ) = @_;
    my ( $side, $lhs_ref ) = @{$lhs};

    my $rhs_ref = coerce_to_R($rhs);

    # If the LHS is actually an rvalue,
    # it is the name of a variable
    # passed up from a 'scalar' rule.
    # In this 'toy' semantics, that's how
    # variables are "declared".
    if ( $side eq 'R' ) {
        my $name = ${$lhs_ref};
        if ( not defined $name or ref $name ) {
            die 'assignment to non-lvalue: ', Data::Dumper::Dumper($name);
        }
        my $v = ${$rhs_ref};
        $SYMTAB{SCALAR}->{$name} = \$v;
        $lhs_ref = \( $SYMTAB{SCALAR}->{$name} );
        return [ 'L', $lhs_ref ];
    } ## end if ( $side eq 'R' )

    if ( Scalar::Util::readonly ${ ${$lhs_ref} } ) {
        die 'lhs is read only!';
    }
    ${ ${$lhs_ref} } = ${$rhs_ref};
    return [ 'L', $lhs_ref ];
} ## end sub do_assign

sub do_THING {
    my ( undef, $value ) = @_;
## no critic (BuiltinFunctions::ProhibitStringyEval)
    $value = eval $value;
    return [ 'R', \$value ];
}

sub do_anon_array {
    my ( undef, undef, $expr ) = @_;
    my $value_ref = coerce_to_R($expr);
    my @result    = ();
    PROCESS_BY_REFTYPE: {
        my $reftype = Scalar::Util::reftype $value_ref;
        if ( $reftype eq 'SCALAR' ) {
            push @result, ${$value_ref};
            last PROCESS_BY_REFTYPE;
        }
        if ( $reftype eq 'REF' ) {
            push @result, ${$value_ref};
            last PROCESS_BY_REFTYPE;
        }
        if ( $reftype eq 'ARRAY' ) {
            push @result, @{$value_ref};
            last PROCESS_BY_REFTYPE;
        }
        if ( $reftype eq 'HASH' ) {
            push @result, %{$value_ref};
            last PROCESS_BY_REFTYPE;
        }
        die "Unknown expr type: ref to $_";
    } ## end PROCESS_BY_REFTYPE:
    return [ 'L', \\[@result] ];
} ## end sub do_anon_array

sub do_anon_empty_array {
    return [ 'L', \\[] ];
}

sub do_anon_hash {
    my ( undef, undef, $expr ) = @_;
    my $value_ref = coerce_to_R($expr);
    my $result;
    PROCESS_BY_REFTYPE: {
        my $reftype = Scalar::Util::reftype $value_ref;
        die 'expr for anon hash cannot be REF'    if $reftype eq 'REF';
        die 'expr for anon hash cannot be SCALAR' if $reftype eq 'SCALAR';
        if ( $reftype eq 'ARRAY' ) {
            $result = { @{$value_ref} };
            last PROCESS_BY_REFTYPE;
        }
        if ( $reftype eq 'HASH' ) {
            $result = \%{$value_ref};
            last PROCESS_BY_REFTYPE;
        }
        die "Unknown expr type: ref to $_";
    } ## end PROCESS_BY_REFTYPE:
    return [ 'R', \$result ];
} ## end sub do_anon_hash

sub do_anon_empty_hash {
    return [ 'R', \{} ];
}

# This assume that all 'my' variables
# are just ways to create
# undef lvalue's -- which is how
# Data::Dumper uses them
sub do_term_my {
    my $v = undef;
    return [ 'L', \\$v ];
}

# Very simplified here --
# References are dereferenced and passed up.
# All scalars not
# already defined are returned as strings.
# It is assumed that they will either be the only
# thing on the LHS of an assignment, or in
# a my declaration.  Data::Dumper uses my
# declarations to create undef's so the scalar
# names
# that go up to term_my's will be thrown away.
sub do_scalar {
    my ( undef, $dollar, $tagged_ob ) = @_;
    my ( $side, $ob_ref ) = @{$tagged_ob};
    if ( $side eq 'R' ) {
        my $name    = ${$ob_ref};
        my $scalars = $SYMTAB{SCALAR};
        if ( exists $scalars->{$name} ) {
            return [ 'L', \$scalars->{$name} ];
        }
        return [ 'R', \$name ];
    } ## end if ( $side eq 'R' )
    $ob_ref = ${$ob_ref};
    my $ob = ${$ob_ref};
    if ( ref $ob ) {
        return [ 'L', \$ob ];
    }
    return [ 'R', $ob ];
} ## end sub do_scalar

sub do_uniop {
    my ( undef, $op ) = @_;
    die "Unknown uniop: $op" if $op ne 'undef';
    return [ 'R', \undef ];
}

# refgen is always an rvalue
sub do_refgen {
    my ( undef, undef, $s1 ) = @_;
    return [ 'R', \coerce_to_R($s1) ];
}

# prog should always return an rvalue
sub do_prog {
    my ( undef, $s1 ) = @_;
    return [ 'R', coerce_to_R($s1) ];
}

sub symbol_1 {
    my ( undef, $s1 ) = @_;
    return $s1;
}

sub symbol_2 {
    my ( undef, undef, $s2 ) = @_;
    return $s2;
}

sub token_1 {
    my ( undef, $a ) = @_;
    return [ 'R', \$a ];
}

my %unwrapped = (
    and_expr__t               => \&symbol_1,
    anon_empty_hash           => \&do_anon_empty_hash,
    anon_hash                 => \&do_anon_hash,
    argexpr__comma            => \&symbol_1,
    argexpr                   => \&do_argexpr,
    argexpr__t                => \&symbol_1,
    array_index               => \&do_array_index,
    array_index_r             => \&do_array_index,
    block                     => \&symbol_2,
    do_block                  => \&symbol_2,
    expr                      => \&symbol_1,
    hash_index                => \&do_hash_index,
    hash_index_r              => \&do_hash_index,
    indirob__block            => \&symbol_1,
    indirob__WORD             => \&token_1,
    lineseq__line             => \&symbol_2,
    line__sideff              => \&symbol_2,
    listexpr                  => \&symbol_1,
    myterm_scalar             => \&symbol_1,
    or_expr__t                => \&symbol_1,
    prog                      => \&do_prog,
    refgen                    => \&do_refgen,
    scalar                    => \&do_scalar,
    sideff                    => \&symbol_1,
    term_addop__t             => \&symbol_1,
    term_andand__t            => \&symbol_1,
    term_arrow__t             => \&symbol_1,
    term_assign               => \&do_assign,
    term_assign_lstop         => \&do_assign,
    term_assign__t            => \&symbol_1,
    term_bitandop__t          => \&symbol_1,
    term_bitorop__t           => \&symbol_1,
    term_cond__t              => \&symbol_1,
    term_dotdot__t            => \&symbol_1,
    term_eqop__t              => \&symbol_1,
    term_hi__anon_array       => \&do_anon_array,
    term_hi__anon_empty_array => \&do_anon_empty_array,
    term_hi__arrow_array      => \&do_term_hi__arrow_array,
    term_hi__arrow_hash       => \&do_term_hi__arrow_hash,
    term_hi__parens           => \&symbol_2,
    term_hi__scalar           => \&symbol_1,
    term_hi__subscripted      => \&symbol_1,
    term_hi__THING            => \&do_THING,
    term_increment__t         => \&symbol_1,
    term_listop__t            => \&symbol_1,
    term_lstop                => \&do_term_lstop,
    term_matchop__t           => \&symbol_1,
    term_mulop__t             => \&symbol_1,
    term_my                   => \&do_term_my,
    term_notop__t             => \&symbol_1,
    term_oror__t              => \&symbol_1,
    term_powop__t             => \&symbol_1,
    term_relop__t             => \&symbol_1,
    term_require__t           => \&symbol_1,
    term_shiftop__t           => \&symbol_1,
    term__t                   => \&symbol_1,
    term_uminus__t            => \&symbol_1,
    term_uniop__t             => \&symbol_1,
    uniop                     => \&do_uniop,
);

sub gen_closure {
    my ( $lhs, $rhs, $action ) = @_;
    my $closure = $unwrapped{$action};
    die "lhs=$lhs: $closure is not a closure"
        if defined $closure and ref $closure ne 'CODE';
    if ( not defined $closure and scalar @{$rhs} <= 0 ) {
        $closure = sub { undef; }
    }
    return sub {
        if ( not defined $closure ) {
            die qq{No action ("$action") defined for },
                "$lhs ::= " . ( join q{ }, map { $_ // q{-} } @{$rhs} );
        }
        my $v = $closure->(@_);
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 0;

        # local $Data::Dumper::Maxdepth = 4;
        push @main::OUTPUT,
              "$lhs ::= "
            . ( join q{ }, map { $_ // q{-} } @{$rhs} ) . q{; }
            . Data::Dumper::Dumper( \$v );
        $v;
    };
} ## end sub gen_closure

my %symbol  = ();
my %closure = ();

## Tests from dumper.t

my $parser = Marpa::R2::Perl->new( { closures => \&gen_closure } );

# Perlcritic cannot figure out that $a and $b are not magic variables
# for a sort comparison

# Trivial
if (1) {
    my $a = 1;
    test( [$a], [qw(a)] );
}

if (1) {
    my @c = ('c');
    my $c = \@c;
    my $b = {};
    my $a = [ 1, $b, $c ];
    $b->{a} = $a;
    $b->{b} = $a->[1];
    $b->{c} = $a->[2];

    test( [ $a, $b, $c ], [qw(a b c)] );
} ## end if (1)

if (1) {
    my $foo = {
        "abc\N{NULL}\'\efg" => "mno\N{NULL}",
        'reftest'           => \\1,
    };

    test( [$foo], [qw($foo)] );
} ## end if (1)

if (1) {
    my $foo = 5;
    my @foo = ( -10, \$foo );
    my %foo = ( a => 1, b => \$foo, c => \@foo );
    $foo{d} = \%foo;
    $foo[2] = \%foo;

    test( [ \%foo ], [qw($foo)] );
} ## end if (1)

if (1) {
    my @dogs   = qw( Fido Wags );
    my %kennel = (
        First  => \$dogs[0],
        Second => \$dogs[1],
    );
    $dogs[2] = \%kennel;
    my $mutts = \%kennel;
    eval {
        test( [ \@dogs, \%kennel, $mutts ], [qw($dogs $kennel $mutts)] );
        1;
    }
        or die "Eval failed: $EVAL_ERROR";
} ## end if (1)

if (1) {
    my $a = [];
    $a->[1] = \$a->[0];
    test( [$a], [qw($a)] );
}

if (1) {
    my $a = \\\\\'foo';
    my $b = ${ ${$a} };
    test( [ $a, $b ], [qw($a $b)] );
}

if (1) {
    ## no critic (Variables::RequireLocalizedPunctuationVars)
    my $b;
    my $a = [ { a => \$b }, { b => undef } ];
    $b = [ { c => \$b }, { d => \$a } ];
    test( [ $a, $b ], [qw($a $b)] );
} ## end if (1)

if (1) {
    my $a = [ [ [ [ \\\\\'foo' ] ] ] ];
    my $b = $a->[0][0];
    my $c = ${ ${ $b->[0][0] } };
    test( [ $a, $b, $c ], [qw($a $b $c)] );
} ## end if (1)

if (1) {
    my $f = 'pearl';
    my $e = [$f];
    my $d = { 'e' => $e };
    my $c = [$d];
    my $b = { 'c' => $c };
    my $a = { 'b' => $b };
    test( [ $a, $b, $c, $d, $e, $f ], [qw($a $b $c $d $e $f)] );
} ## end if (1)

if (1) {
    ## no critic (Variables::RequireLocalizedPunctuationVars)
    my $a;
    $a = \$a;
    my $b = [$a];
    test( [$b], [qw($b)] );
} ## end if (1)

## Test from Randal Schwartz

if (1) {
    my $x = bless { fred => 'flintstone' }, 'x';
    my $y = bless \$x, 'y';
    test( [ $x, $y ], [qw($x $y)] );
}

## no critic (Subroutines::RequireArgUnpacking)
sub test {

    my $input = Data::Dumper->new(@_)->Purity(1)->Sortkeys(1)->Dump;

    # Table by type and name of data
    # All data is kept as refs.
    # For orthogonality, that includes scalars.
    %SYMTAB = ();
    @OUTPUT = ();

    my $value_ref = $parser->parse( \$input );
    if ( not defined $value_ref ) {
        die 'Perl parse failed';
    }
    my @pointers = ();
    my @names    = ();
    for my $type ( sort keys %SYMTAB ) {
        my $sigil =
              $type eq 'SCALAR' ? q{$}
            : $type eq 'REF'    ? q{$}
            : $type eq 'ARRAY'  ? q{@}
            : $type eq 'HASH'   ? q{@}
            :                     q{!};
        my $symbols_by_name = $SYMTAB{$type};
        for my $name ( sort keys %{$symbols_by_name} ) {
            my $ref = $symbols_by_name->{$name};

            # The testing convention is to pass scalars directly
            $type eq 'SCALAR' and $ref = ${$ref};
            push @pointers, $ref;
            push @names,    "$sigil$name";
        } ## end for my $name ( sort keys %{$symbols_by_name} )
    } ## end for my $type ( sort keys %SYMTAB )
    my $output =
        Data::Dumper->new( \@pointers, \@names )->Purity(1)->Sortkeys(1)
        ->Dump;
    Test::More::is( $output, $input );
    return;

} ## end sub test

# vim: expandtab shiftwidth=4:
