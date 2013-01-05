use 5.010;
use strict;
use Marpa::R2 2.039_000;


sub do_dwim {
    shift;
    return shift if scalar @_ <= 1;
    return \@_;
}

my $g = Marpa::R2::Scanless::G->new({
    default_action => do_dwim,
    source         => \(<<'END_OF_SOURCE'),

:start        ::= string
string        ::= '""'
                | '"' in_string '"'

in_string       ~ [^"]+

:discard        ~ ws
ws              ~ [\s]+

END_OF_SOURCE
});

my $string = <<"INPUT";
""
INPUT
# my $string = '""';

my $re = Marpa::R2::Scanless::R->new({ grammar => $g });
$re->read(\$string);
say ${$re->value()};
