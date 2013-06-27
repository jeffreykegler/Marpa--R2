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

:lexeme ~ string pause => before event => 'before string'

# Just look for the first double quote, and do the rest in the external scanner
string ~ ["]

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
            if ( $event_name eq 'before string' ) {
		my $eos = index $string, q{"}, $pos + 1;
		while ((substr $string, $eos - 1, 1) eq '\\') {
	      $DB::single = 1;
		  $eos = index $string, q{"}, $eos + 1;
		}
		my $value = substr $string, $pos+1, $eos - $pos - 1;
		# say STDERR qq{string is '$value'};
                $value = decode_string($value) if 0 >= index $value, '\\';
                $re->lexeme_read( 'string', $pos, $eos - $pos + 1, $value ) // die;
                $pos = $eos + 1;
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
    return { map { @{$_} } @{$members} };
}

sub do_true {
    shift;
    return $_[0] eq 'true';
}

1;
