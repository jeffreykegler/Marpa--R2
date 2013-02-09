package MarpaX::JSON;
use strict;
use Marpa::R2 2.039_000;

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    $self->{grammar} = Marpa::R2::Scanless::G->new(
        {
            action_object  => 'MarpaX::JSON::Actions',
            default_action => '::dwim',
            source         => \(<<'END_OF_SOURCE'),

:start       ::= json

json         ::= object
               | array

object       ::= '{' '}'               action => do_empty_object
               | '{' members '}'       action => do_object

members      ::= pair+                 separator => <comma> action => ::array

pair         ::= string (':') value      action => ::array

value        ::= string
               | object
               | number
               | array
               | 'true'                action => do_true
               | 'false'               action => do_true
               | 'null'                action => ::undef

array        ::= '[' ']'               action => do_empty_array
               | ('[') elements (']')      action => ::first

elements     ::= value+                separator => <comma> action => ::array

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

string       ::= lstring               action => do_string

lstring        ~ quote in_string quote
quote          ~ ["]

in_string      ~ in_string_char*

in_string_char  ~ [^"\\]
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
hex_digit       ~ [0-9a-fA-F]

comma          ~ ','

:discard       ~ whitespace
whitespace     ~ [\s]+

END_OF_SOURCE

        }
    );
    return $self;
}

sub parse {
    my ($self, $string) = @_;
    my $re = Marpa::R2::Scanless::R->new( { grammar => $self->{grammar} } );
    $re->read(\$string);
    my $value_ref = $re->value();
    return ${$value_ref};
}

sub parse_json {
    my ($string) = @_;
    my $parser = MarpaX::JSON->new();
    return $parser->parse($string);
}

package MarpaX::JSON::Actions;
use strict;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub do_empty_object {
    return {};
}

sub do_object {
    shift;
    return { map { @$_ } @{$_[1]} };
}

sub do_empty_array {
    return [];
}

sub do_string {
    shift;
    my $s = $_[0];

    $s =~ s/^"//;
    $s =~ s/"$//;

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

sub do_true {
    shift;
    return $_[0] eq 'true';
}

sub do_join {
    shift;
    return join '', @_;
}

1;
