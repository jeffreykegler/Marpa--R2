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
  last VALUE if not $value_ref;
  my $value = $$value_ref;
  my @target_desc = @{$value};
  # say Data::Dumper::Dumper(\@target_desc);
  my ($start, $length) = @{$target_desc[0]};
  say "Match found at $start, length=$length";
}

