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

use 5.010;

use Data::Dumper;
use Marpa::R2;

my $grammar = Marpa::R2::Scanless::G->new(
    {   source        => \(<<'END_OF_DSL'),
:default ::= action => [name,values]
lexeme default = action => [ start, length, value ]
    latm => 1

# standard part of grammar
top ::= prefix target suffix action => My_Actions::top
prefix ::= any* action => ::undef
suffix ::= any* action => ::undef
any ~ [\D\d]

# custom part of grammar
target ::= x_pair+ action => [ start, length ]
x_pair ::= 'x' 'x'
END_OF_DSL
    }
);

sub My_Actions::top {
    my ($ppo, @children) = @_;
    return [grep { $_ } @children ];
}

my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

my $input = 'yyyxxxyyyyyxxxxxyyyyxyyyyxxyyyyxxxxyyy';
$recce->read(\$input);
VALUE: while (1) {
  my $value_ref = $recce->value();
  say $recce->thin()->show_earley_sets();
  last VALUE if not $value_ref;
  my $value = $$value_ref;
  my @target_desc = @{$value};
  # say Data::Dumper::Dumper(\@target_desc);
  my ($start, $length) = @{$target_desc[0]};
  say "Match found at $start, length=$length";
}

