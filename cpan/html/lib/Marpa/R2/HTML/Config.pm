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

package Marpa::R2::HTML::Config;

use 5.010001;
use strict;
use warnings;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '11.004_000';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

use English qw( -no_match_vars );

# Generate the default configuration
sub new {
    my ($class) = @_;
    require Marpa::R2::HTML::Config::Default;
    my $self = {
        rules => $Marpa::R2::HTML::Internal::Config::Default::CORE_RULES,
        runtime_tag =>
            $Marpa::R2::HTML::Internal::Config::Default::RUNTIME_TAG,
        ruby_slippers_rank_by_name =>
            $Marpa::R2::HTML::Internal::Config::Default::RUBY_SLIPPERS_RANK_BY_NAME,
        is_empty_element =>
            $Marpa::R2::HTML::Internal::Config::Default::IS_EMPTY_ELEMENT,
        primary_group_by_tag =>
            $Marpa::R2::HTML::Internal::Config::Default::PRIMARY_GROUP_BY_TAG
    };
    return bless $self, $class;
} ## end sub new

sub new_from_compile {
    my ( $class, $source_ref ) = @_;
    require Marpa::R2::HTML::Config::Compile;
    return bless Marpa::R2::HTML::Config::Compile::compile($source_ref), $class;
} ## end sub new_from_compile

sub contents {
    my ($self) = @_;
    return @{$self}{
        qw( rules runtime_tag
            ruby_slippers_rank_by_name is_empty_element
            primary_group_by_tag
            )
        };
} ## end sub contents

my $legal_preamble = <<'END_OF_TEXT';
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

END_OF_TEXT

sub sort_bnf {
    my $cmp = $a->{lhs} cmp $b->{lhs};
    return $cmp if $cmp;
    my $a_rhs_length = scalar @{ $a->{rhs} };
    my $b_rhs_length = scalar @{ $b->{rhs} };
    $cmp = $a_rhs_length <=> $b_rhs_length;
    return $cmp if $cmp;
    for my $ix ( 0 .. $a_rhs_length ) {
        $cmp = $a->{rhs}->[$ix] cmp $b->{rhs}->[$ix];
        return $cmp if $cmp;
    }
    return 0;
} ## end sub sort_bnf

sub as_string {
    my ($self) = @_;

    require Data::Dumper;
    require Marpa::R2::HTML::Config::Default;

    local $Data::Dumper::Purity   = 1;
    local $Data::Dumper::Sortkeys = 1;
    my @contents = $self->contents();
    my @rules = sort sort_bnf @{$contents[0]};
    $contents[0] = \@rules;

    # Start with the legal language
    return \(
              $legal_preamble
            . '# This file was generated automatically by '
            . __PACKAGE__ . "\n"
            . '# The date of generation was '
            . ( scalar localtime() ) . "\n" . "\n"
            . "package Marpa::R2::HTML::Internal::Config::Default;\n" . "\n"
            . Data::Dumper->Dump(
            \@contents,
            [   qw( CORE_RULES RUNTIME_TAG
                    RUBY_SLIPPERS_RANK_BY_NAME IS_EMPTY_ELEMENT
                    PRIMARY_GROUP_BY_TAG
                    )
            ]
            )
    );

} ## end sub as_string

1;

# vim: set expandtab shiftwidth=4:
