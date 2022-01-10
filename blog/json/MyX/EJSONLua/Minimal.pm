#!env perl
# =================================
# JSON with minimal actions in Lua
# =================================

package MyX::EJSONLua::Minimal;
use parent qw/MyX::EJSONLua/;
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
members             ::= member*                   separator => ',' proper => 1                     action => ::lua->members
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
                      | /(?:\\["\\\/bfnrt])+/                                                      action => ::lua->string_escape_part
                      | /(?:\\u[[:xdigit:]]{4})+/                                                  action => ::lua->string_unicode_part


# -------------
# JSON constant
# -------------
constant            ::= 'true'                                                                     action => ::true
                      | 'false'                                                                    action => ::false
                      | 'null'                                                                     action => ::undef
                     

# -----------
# JSON number
# -----------
number              ::= /-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/                     action => ::lua->number

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
