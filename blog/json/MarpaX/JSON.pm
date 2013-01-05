package MarpaX::JSON;
use strict;
use Marpa::R2;

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    $self->{grammar} = Marpa::R2::Scanless::G->new(
        {
            action_object  => 'MarpaX::JSON::Actions',
            default_action => 'do_first_arg',
            source         => \(<<'END_OF_SOURCE'),

:start       ::= json

json         ::= object
               | array

object       ::= '{' '}'               action => do_empty_object
               | '{' members '}'       action => do_object

members      ::= pair+                 separator => <comma> action => do_list

pair         ::= string ':' value      action => do_pair

value        ::= string
               | object
               | number
               | array
               | 'true'                action => do_true
               | 'false'               action => do_true
               | 'null'                action => do_null

array        ::= '[' ']'               action => do_empty_array
               | '[' elements ']'      action => do_array

elements     ::= value+                separator => <comma> action => do_list

number       ~ int
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
in_string      ~ [^"]*

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
use Data::Dumper;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub do_first_arg {
    shift;
    return $_[0];
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

sub do_array {
    shift;
    return $_[1];
}

sub do_list {
    shift;
    return \@_;
}

sub do_pair {
    shift;
    return [ $_[0], $_[2] ];
}

sub do_string {
    shift;
    my $s = $_[0];
    $s =~ s/^"//;
    $s =~ s/"$//;
    return $s;
}

sub do_true {
    shift;
    return $_[0] eq 'true';
}

sub do_null {
    return undef;
}

1;
