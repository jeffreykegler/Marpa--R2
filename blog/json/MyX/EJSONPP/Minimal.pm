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

use MarpaX::ESLIF;
use SUPER;

sub new {
    my ($class, $log) = @_;

    my $eslif = MarpaX::ESLIF->new($log); # This is a multiton
    my $eslifJson = MarpaX::ESLIF::Grammar->new($eslif, do { local $/; <DATA> });

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
