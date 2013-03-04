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

package Marpa::R2::Stuifzand;

use 5.010;
use strict;
use warnings;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.047_007';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

package Marpa::R2::Internal::Stuifzand;

use English qw( -no_match_vars );

# Internal names end in ']' and are distinguished by prefix.
#
# Suffixed with '[prec%d]' --
# a symbol created to implement precedence.
# Suffix is removed to restore 'original'.
#
# Prefixed with '[[' -- a character class
# These are their own 'original'.
#
# Prefixed with '[:' -- a reserved symbol, one which in the
# grammars start with a colon.
# These are their own 'original'.
#
# Of the form '[Lex-42]' - where for '42' any other
# decimal number can be subsituted.  Anonymous lexicals.
# These symbols are their own originals.
#
# Prefixed with '[SYMBOL#' - a unnamed internal symbol.
# Seeing these
# indicates some sort of internal error.  If seen,
# they will be treated as their own original.
# 
# Suffixed with '[Sep]' indicates an internal version
# of a sequence separator.  These are their own
# original, because otherwise the "original" name
# would conflict with the LHS of the sequence.
# 

# Undo any rewrite of the symbol name
sub Marpa::R2::Grammar::original_symbol_name {
   $_[0] =~ s/\[ prec \d+ \] \z//xms;
   return shift;
}

sub last_rule {
   my ($meta_recce) = @_;
   my ($start, $end) = $meta_recce->last_completed_range( 'rule' );
   return 'No rule was completed' if not defined $start;
   return $meta_recce->range_to_string( $start, $end);
}

sub parse_rules {
    my ( $thick_grammar, $p_rules_source ) = @_;
    $DB::single = 1;
    my $self       = {};
    my $ast        = Marpa::R2::Internal::MetaAST->new($p_rules_source);
    my $hashed_ast = $ast->ast_to_hash($p_rules_source);
    $self->{rules} = $hashed_ast->{g1_rules};
    return $self;
} ## end sub parse_rules

1;

# vim: expandtab shiftwidth=4:
