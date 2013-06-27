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
            source         => \(<<'END_OF_SOURCE'),
:default ::= action => ::first

:start       ::= json

json         ::= object
               | array

object       ::= ('{') members ('}')       action => do_object

members      ::= pair*                 action => ::array separator => <comma>

pair         ::= string (':') value action => ::array

value        ::= string
               | object
               | number
               | array
               | 'true'                action => do_true
               | 'false'               action => do_true
               | 'null'                action => ::undef


array        ::= ('[' ']')               action => []
               | ('[') elements (']') 

elements     ::= value+                action => ::array separator => <comma>

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

string       ::= <complex string>
string       ::= <simple string>

:lexeme ~ <complex string> pause => before event => 'before complex string'
:lexeme ~ <simple string> pause => before event => 'before simple string'

# complex string contains at least one backslashed char
<complex string> ~ quote <simple string chars> <backslashed char> <complex string chars> quote
<complex string chars> ~ <complex string char>+
<complex string char> ~ <simple string char> | <backslashed char>
<simple string> ~ quote <simple string chars> quote
<simple string chars> ~ <simple string char>*
quote ~ ["]
backslash      ~ [\x5c]
<backslashed char> ~ backslash [\d\D]
<simple string char> ~ [^"\x5c]

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
    my $length = length $string;
    READ: for (
        my $pos = $re->read( \$string );
        $pos < $length;
        $pos = $re->resume($pos)
        )
    {
        for my $event ( @{$re->events()} ) {
            my ($event_name) = @{$event};
	      $DB::single = 1;
            if ( $event_name eq 'before simple string' ) {
                my ( $start, $length ) = $re->pause_span();
                my $value = substr $string, $start + 1, $length - 2;
		# say STDERR "$event_name value=$value";
                $re->lexeme_read( 'simple string', $start, $length, $value ) // die;
                $pos = $start + $length;
                next READ;
	    }
            if ( $event_name eq 'before complex string' ) {
                my ( $start, $length ) = $re->pause_span();
                my $value = substr $string, $start + 1, $length - 2;
		# say STDERR "$event_name value=$value";
                $value = decode_string($value);
                $re->lexeme_read( 'complex string', $start, $length, $value ) // die;
                $pos = $start + $length;
                next READ;
            } ## end if ( $event_name eq 'before complex string' )
        } ## end EVENT: for my $event ( $re->events() )
	die "Paused but no event";
    } ## end for ( my $pos = $re->read( \$string ); $pos < $length...)
    my $value_ref = $re->value();
    return ${$value_ref};
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
    use Data::Dumper;
    return { map { @{$_} } @{$members} };
}

sub do_true {
    shift;
    return $_[0] eq 'true';
}

1;
