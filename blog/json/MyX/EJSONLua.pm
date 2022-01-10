#!env perl
# =========================================
# JSON with 100% of the actions done in lua
# =========================================
#
# Streaming interface
#
package MyX::EJSONLua::MyRecognizerInterface;
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
package MyX::EJSONLua::MyValueInterface;
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

package MyX::EJSONLua;
#
# Parser
#

use 5.010;
use strict;
use warnings;

use Carp qw/croak/;
use MarpaX::ESLIF;

sub new {
    my ($class, $log) = @_;

    my $eslif = MarpaX::ESLIF->new($log); # This is a multiton
    my $eslifJson = MarpaX::ESLIF::Grammar->new($eslif, do { local $/; <DATA> });

    return $eslifJson;
}

sub doparse {
    my ($self, $input) = @_;

    my $recognizerInterface = MyX::EJSONLua::MyRecognizerInterface->new(data => $input);
    my $valueInterface      = MyX::EJSONLua::MyValueInterface->new();

    croak 'Parse failure' unless $self->parse($recognizerInterface, $valueInterface);

    return $valueInterface->getResult;
}

1;

__DATA__
# --------------------------------------------------
# Meta settings
# --------------------------------------------------
:desc               ::= 'Strict JSON Grammar'
:default            ::= action => ::luac->function(...) return select(1, ...) end fallback-encoding => UTF-8 discard-is-fallback => 1

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
object              ::= '{' members '}'                                        action => ::luac->function(lsquare, members, rsquare) return members end
members             ::= member*                   separator => ',' proper => 1 action => ::lua->members
member              ::= string ':' value                                       action => ::luac->function(string, column, value) return niledarray(string, value) end

# ----------
# JSON Array
# ----------
array               ::= '[' elements ']'                                       action => ::luac->function(lbracket, elements, rbracket) return elements end
elements            ::= value*                    separator => ',' proper => 1 action => ::lua->elements

# -----------
# JSON String
# -----------
string              ::= '"' string_parts '"'                                   action => ::luac->function(dquote, string_parts, dquote) return string_parts end
string_parts        ::= string_part*                                           action => ::luac->function(...) return table.concat({...}) end
string_part         ::= /[^"\\\x00-\x1F]+/u
                      | /(?:\\["\\\/bfnrt])+/                                  action => ::lua->string_escape_part
                      | /(?:\\u[[:xdigit:]]{4})+/                              action => ::lua->string_unicode_part


# -------------
# JSON constant
# -------------
constant            ::= 'true'                                                 action => ::luac->function(input) return true end
                      | 'false'                                                action => ::luac->function(input) return false end
                      | 'null'                                                 action => ::luac->function(input) return nil end
                     

# -----------
# JSON number
# -----------
number              ::= /-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/ action => ::lua->number

<luascript>
-- Action for: members ::= member*
----------------------------------
function members(...)
    local narg = select('#', ...)
    local output = niledtablekv()

    if narg > 0 then
        for n=1,narg,2 do
            local member = select(n, ...)
            output[member[1]] = member[2]
        end
    end

    return output
end

-- Action for: elements ::= value*
-- ----------------------------------------
function elements(...)
    local narg = select('#', ...)
    local output = niledarray()

    if narg > 0 then
        local i = 1
        for n=1,select('#', ...),2 do
            output[i] = select(n, ...)
            i = i + 1
        end
    end

    return output
end

-- Action for: /(?:\\["\\\/bfnrt])+/
-----------------------------------
function string_escape_part(part)
    local c = part:sub(2, 2)

    if     c == 'b' then c = '\b'
    elseif c == 'f' then c = '\f'
    elseif c == 'n' then c = '\n'
    elseif c == 'r' then c = '\r'
    elseif c == 't' then c = '\t'
    end

    return c
end

-- Action for: /(?:\\u[[:xdigit:]]{4})+/
----------------------------------------
function string_unicode_part(part)
    local stringtable = {}
    local uint32 = {}
    local p = 1
    local pmax = part:len()
    while p <= pmax do
        local u = part:sub(p+2, p + 5)
        uint32[#uint32+1] = tonumber('0x'..u)
        p = p + 6
    end
    local j = 2
    for i = 1, #uint32 do
        local u = uint32[i]
        if ((j <= #uint32) and (u >= 0xD800) and (u <= 0xDBFF) and (uint32[j] >= 0xDC00) and (uint32[j] <= 0xDFFF)) then
            -- Surrogate UTF-16 pair
            u = 0x10000 + ((u & 0x3FF) << 10) + (uint32[j] & 0x3FF)
            i = i + 1
            j = j + 1
        end
        if ((u >= 0xD800) and (u <= 0xDFFF)) then
            u = 0xFFFD -- Replacement character
        end
        c = utf8.char(u)
        stringtable[#stringtable + 1] = c
    end
    return table.concat(stringtable)
end

-- Action for: /-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/
---------------------------------------------------------------------
function number(input)
    return tonumber(input)
end
</luascript>
