#!env perl
# ==========================================
# JSON with 100% of the actions done in perl
# ==========================================
#
# Streaming interface
#
package MyRecognizerInterface;
use Moo;
use strictures 2;
use namespace::clean;

has 'data'                   => ( is => 'ro' );                       # Input
has 'read'                   => ( is => 'ro', default => sub { 1 } ); # First read is ok
has 'isEof'                  => ( is => 'ro', default => sub { 1 } ); # First read reaches EOF
has 'isCharacterStream'      => ( is => 'ro', default => sub { 1 } ); # This is a stream of characters
has 'encoding'               => ( is => 'ro', default => sub {   } ); # Let ESLIF guess
has 'isWithDisableThreshold' => ( is => 'ro', default => sub { 0 } ); # Do not disable Marpa threshold warnings
has 'isWithExhaustion'       => ( is => 'ro', default => sub { 0 } ); # Do not generate exhaustion event
has 'isWithNewline'          => ( is => 'ro', default => sub { 1 } ); # Count newlines for nice error reporting
has 'isWithTrack'            => ( is => 'ro', default => sub { 0 } ); # Do not track input terminals

#
# Value interface
#
package MyValueInterface;
use JSON::Any; # For true/false
use Moo;
use strictures 2;
use namespace::clean;

has 'result'                => ( is => 'rw', reader => 'getResult', writer => 'setResult' );
has 'isWithHighRankOnly'    => ( is => 'ro', default => sub { 1 } ); # Only highest rank (not used in JSON grammar)
has 'isWithOrderByRank'     => ( is => 'ro', default => sub { 1 } ); # Order by rank (not used in JSON grammar)
has 'isWithAmbiguous'       => ( is => 'ro', default => sub { 0 } ); # No ambiguous valuation
has 'isWithNull'            => ( is => 'ro', default => sub { 0 } ); # No null parse
has 'maxParses'             => ( is => 'ro', default => sub { 0 } ); # No max number of parses

#
# shift action
# --------------------------------------
sub perl_shift {
    my ($self, $this) = @_;

    return $this
}

#
# Action for: object ::= '{' members '}'
# --------------------------------------
sub object {
    my ($self, $start, $members, $end) = @_;

    return $members
}

#
# Action for: array ::= '[' elements ']'
# --------------------------------------
sub array {
    my ($self, $start, $elements, $end) = @_;

    return $elements
}

#
# Action for: string ::= '"' string_parts '"'
# -------------------------------------------
sub string {
    my ($self, $start, $string_parts, $end) = @_;

    return $string_parts
}

#
# Action for: string_parts ::= string_part*
# -----------------------------------------
sub string_parts {
    my ($self) = shift;

    return join('', @_)
}

#
# Action for: members ::= member*
# -------------------------------
sub members {
    my ($self) = shift;

    my %output = ();
    while (@_) {
        my $member = pop(@_);
        $output{$member->[0]} = $member->[1];
        #
        # Eat separator
        #
        pop(@_);
    }

    return \%output
}

#
# Action for: member ::= string ':' value
# ----------------------------------------
sub member {
    my ($self, $string, $comma, $value) = @_;

    return [ $string, $value ]
}

#
# Action for: elements ::= value*
# ----------------------------------------
sub elements {
    my ($self) = shift;

    my @output = ();
    while (@_) {
        my $value = pop(@_);
        push(@output, $value);
        #
        # Eat separator
        #
        pop(@_);
    }

    return \@output
}

#
# Action for: /(?:\\["\\\/bfnrt])+/
# ---------------------------------
sub string_escape_part {
    my ($self, $part) = @_;

    my $c = substr($part, 0, 1);

    if    ($c eq 'b') { $c = '\b' }
    elsif ($c eq 'f') { $c = '\f' }
    elsif ($c eq 'n') { $c = '\n' }
    elsif ($c eq 'r') { $c = '\r' }
    elsif ($c eq 't') { $c = '\t' }

    return $c
}

#
# Action for: /(?:\\u[[:xdigit:]]{4})+/
# -------------------------------------
sub string_unicode_part {
    my ($self, $part) = @_;

    my @uint32 = ();
    my $p = 0;
    my $pmax = length($part);
    my $output;

    while ($p < $pmax) {
        my $u = substr($part, $p+2, 4);
        push(@uint32, hex($u));
        $p += 6;
    }

    for (my $i = 0, my $j = 1; $i <= $#uint32; $i++, $j++) {
        my $c = $uint32[$i];
        if (($j <= $#uint32) && ($c >= 0xD800) && ($c <= 0xDBFF) && ($uint32[$j] >= 0xDC00) && ($uint32[$j] <= 0xDFFF)) {
            # Surrogate UTF-16 pair
            $c = 0x10000 + (($c & 0x3FF) << 10) + ($uint32[$j] & 0x3FF);
            ++$i;
            ++$j;
        }
        if (($c >= 0xD800) && ($c <= 0xDFFF)) {
            $c = 0xFFFD; # Replacement character
        }
        
        if ($c < 0x80) {
            $output .= chr($c);
            next;
        }

        my @q = ();
        if ($c < 0x800) {
            push(@q, 0xC0 + ($c >> 6));
            goto t1;  
        }
        if ($c < 0x10000) {
            push(@q, 0xE0 + ($c >> 12));
            goto t2;
        }
        push(@q, 0xF0 + ($c >> 18));
        push(@q, 0x80 + (($c >> 12) & 0x3F));
      t2:
        push(@q, 0x80 + (($c >> 6) & 0x3F));
      t1:
        push(@q, 0x80 + ($c & 0x3F));

        $c = pack "C*", @q;
        $output .= $c;
    }

    return $output
}

#
# Action for: /-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/
# ------------------------------------------------------------------
sub number {
    my ($self, $number) = @_;

    my $output = 0+$number;

    return $output
}

#
# Action for: constant ::= 'true'
# -------------------------------
sub true {
    my ($self) = @_;

    my $output = JSON::Any->true;
    
    return $output
}

#
# Action for: constant ::= 'false'
# --------------------------------
sub false {
    my ($self) = @_;

    my $output = JSON::Any->false;
    
    return $output
}

#
# Action for: constant ::= 'null'
# -------------------------------
sub null {
    my ($self) = @_;

    my $output = undef;

    return $output
}

package MyX::EJSONPP;
#
# Parser
#

use 5.010;
use strict;
use warnings;

use Carp qw/croak/;
use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;
use MarpaX::ESLIF;

#
# Init log
#
our $defaultLog4perlConf = '
log4perl.rootLogger              = INFO, Screen
log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr  = 0
log4perl.appender.Screen.layout  = PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %6P %m{chomp}%n
';
Log::Log4perl::init(\$defaultLog4perlConf);
Log::Any::Adapter->set('Log4perl');

sub new {

    my $eslif = MarpaX::ESLIF->new($log);
    my $dsl   = do { local $/; <DATA> };
    my $eslifJson = MarpaX::ESLIF::Grammar->new($eslif, $dsl);
    return $eslifJson;
}

sub doparse {
    my ($self, $input) = @_;

    my $recognizerInterface = MyRecognizerInterface->new(data => $input);
    my $valueInterface      = MyValueInterface->new();

    croak 'Parse failure' unless $self->parse($recognizerInterface, $valueInterface);

    return 1
}

1;

__DATA__
# --------------------------------------------------
# Meta settings
# --------------------------------------------------
:desc               ::= 'Strict JSON Grammar'
:default            ::= action => perl_shift fallback-encoding => UTF-8 discard-is-fallback => 1

# ---------------------------------
# Discard unsignificant whitespaces
# ---------------------------------
:discard            ::= /[\x{9}\x{A}\x{D}\x{20}]+/

# ---------------------------------------------------------
# Terminal events : stop temporarly discard within a string
# ---------------------------------------------------------
:symbol             ::= '"' pause => after event => :discard[switch]

# ----------
# JSON value
# ----------
value               ::= object
                      | array
                      | string
                      | constant
                      | number

# -----------
# JSON object
# -----------
object              ::= '{' members '}'                                                            action => object
members             ::= member*                   separator => ',' proper => 1                     action => members
member              ::= string ':' value                                                           action => member

# ----------
# JSON Array
# ----------
array               ::= '[' elements ']'                                                           action => array
elements            ::= value*                    separator => ',' proper => 1                     action => elements

# -----------
# JSON String
# -----------
string              ::= '"' string_parts '"'                                                       action => string
string_parts        ::= string_part*                                                               action => string_parts
string_part         ::= /[^"\\\x00-\x1F]+/u
                      | /(?:\\["\\\/bfnrt])+/                                                      action => string_escape_part
                      | /(?:\\u[[:xdigit:]]{4})+/                                                  action => string_unicode_part


# -------------
# JSON constant
# -------------
constant            ::= 'true'                                                                     action => true
                      | 'false'                                                                    action => false
                      | 'null'                                                                     action => null
                     

# -----------
# JSON number
# -----------
number              ::= /-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/                     action => number
