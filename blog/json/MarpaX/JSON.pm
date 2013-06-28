package MarpaX::JSON;

use 5.010;
use strict;
use warnings;

use Marpa::R2 2.047_011;

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    $self->{grammar} = Marpa::R2::Scanless::G->new(
        {
            action_object  => 'MarpaX::JSON::Actions',
	    bless_package => 'My_Nodes',
            source         => \(<<'END_OF_SOURCE'),
:default ::= action => ::array

:start       ::= json

json         ::= object action => ::first
               | array action => ::first

object       ::= ('{') members ('}') bless => hash

members      ::= pair*                 separator => <comma>

pair         ::= string (':') value

value        ::= string action => ::first
               | object action => ::first
               | number action => ::first
               | array action => ::first
               | 'true' action => ::first
               | 'false' action => ::first
               | 'null' action => ::first


array        ::= ('[' ']')
               | ('[') elements (']') action => ::first

elements     ::= value+                separator => <comma>

number         ~ int
               | int frac
               | int exp
               | int frac exp

int            ~ digits
               | '-' digits

digits         ~ [\d]+

frac           ~ '.' digits

exp            ~ e digits

e              ~ 'e'
               | 'e+'
               | 'e-'
               | 'E'
               | 'E+'
               | 'E-'

string ::= lstring bless => string
 
lstring ~ quote in_string quote
quote ~ ["]
  
in_string ~ in_string_char*
   
in_string_char ~ [^"\\]
   | '\' '"'
   | '\' 'b'
   | '\' 'f'
   | '\' 't'
   | '\' 'n'
   | '\' 'r'
   | '\' 'u' four_hex_digits
   | '\' '/'
   | '\\'
    
four_hex_digits ~ hex_digit hex_digit hex_digit hex_digit
hex_digit ~ [0-9a-fA-F]
     
comma          ~ ','

:discard       ~ whitespace
whitespace     ~ [\s]+

END_OF_SOURCE

        }
    );
    return $self;
}

sub eval_json {
    my ($thing) = @_;
    my $type = ref $thing;
    say STDERR $type;
    if ($type eq 'REF') {
        return \eval_json(${$thing});
    }
    if ($type eq 'ARRAY') {
        return [ map { eval_json($_) } @{$thing} ];
    }
    if ($type eq 'My_Nodes::string') {
        my $string = substr $thing->[0], 1, -1;
	return decode_string($string) if (index $string, '\\') >= 0;
	return $string;
    }
    if ($type eq 'My_Nodes::hash') {
	return { map { eval_json($_->[0]), eval_json($_->[1]) } @{$thing->[0]} };
    }
    return $thing;
}

sub parse {
    my ($self, $string) = @_;
    my $re = Marpa::R2::Scanless::R->new( { grammar => $self->{grammar} } );
    my $length = length $string;
    my $pos = $re->read( \$string );
    die "Read short of end: $pos vs. $length" if $pos < $length;
    my $value_ref = $re->value();
    die "Parse failed" if not defined $value_ref;
    my $value = eval_json($value_ref);
    return $value;
}

sub parse_json {
    my ($string) = @_;
    my $parser = MarpaX::JSON->new();
    return $parser->parse($string);
}

sub decode_string {
    my ($s) = @_;

    $s =~ s/\\u([0-9A-Fa-f]{4})/chr(hex($1))/eg;
    $s =~ s/\\n/\n/g;
    $s =~ s/\\r/\r/g;
    $s =~ s/\\b/\b/g;
    $s =~ s/\\f/\f/g;
    $s =~ s/\\t/\t/g;
    $s =~ s/\\\\/\\/g;
    $s =~ s{\\/}{/}g;
    $s =~ s{\\"}{"}g;

    return $s;
}

package MarpaX::JSON::Actions;
use strict;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub do_object {
    my (undef, $members) = @_;
    return { map { @{$_} } @{$members} };
}

sub do_true {
    shift;
    return $_[0] eq 'true';
}

1;
