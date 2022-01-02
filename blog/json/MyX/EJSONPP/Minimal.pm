#!env perl
# =================================
# JSON with minimal actions in perl
# =================================

package MyX::EJSONPP::Minimal;
use parent qw/MyX::EJSONPP/;
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
use SUPER;

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
    super()
}

1;

__DATA__
# --------------------------------------------------
# Meta settings
# --------------------------------------------------
:desc               ::= 'Strict JSON Grammar'
:default            ::= action => ::shift fallback-encoding => UTF-8 discard-is-fallback => 1

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
object              ::= '{' members '}'                                                            action => ::copy[1]
members             ::= member*                   separator => ',' proper => 1                     action => members
member              ::= string (-':'-) value                                                       action => ::row

# ----------
# JSON Array
# ----------
array               ::= '[' elements ']'                                                           action => ::copy[1]
elements            ::= value*                    separator => ',' proper => 1 hide-separator => 1 action => ::row

# -----------
# JSON String
# -----------
string              ::= '"' string_parts '"'                                                       action => ::copy[1]
string_parts        ::= string_part*                                                               action => ::concat
string_part         ::= /[^"\\\x00-\x1F]+/u
                      | /(?:\\["\\\/bfnrt])+/                                                      action => string_escape_part
                      | /(?:\\u[[:xdigit:]]{4})+/                                                  action => string_unicode_part


# -------------
# JSON constant
# -------------
constant            ::= 'true'                                                                     action => ::true
                      | 'false'                                                                    action => ::false
                      | 'null'                                                                     action => ::undef
                     

# -----------
# JSON number
# -----------
number              ::= /-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/                     action => number
