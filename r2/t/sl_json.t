#!/usr/bin/perl
# Copyright 2013 Jeffrey Kegler
# This file is part of Marpa::R2.  Marpa::R2 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R2.  If not, see
# http://www.gnu.org/licenses/.

# Test using a JSON parser
# Inspired by a parser written by Peter Stuifzand

use 5.010;
use strict;
use warnings;
use Test::More tests => 13;
use English qw( -no_match_vars );
use Scalar::Util qw(blessed);

use lib 'inc';
use Marpa::R2::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R2;

my $data = MarpaX::JSON::parse_json(q${"test":"1"}$);
is($data->{test}, 1);

{
    my $test = q${"test":[1,2,3]}$;
    $data = MarpaX::JSON::parse_json(q${"test":[1,2,3]}$);
    is_deeply( $data->{test}, [ 1, 2, 3 ], $test );
}

$data = MarpaX::JSON::parse_json(q${"test":true}$);
is($data->{test}, 1);

$data = MarpaX::JSON::parse_json(q${"test":false}$);
is($data->{test}, '');

$data = MarpaX::JSON::parse_json(q${"test":null}$);
is($data->{test}, undef);

$data = MarpaX::JSON::parse_json(q${"test":null, "test2":"hello world"}$);
is($data->{test}, undef);
is($data->{test2}, "hello world");

$data = MarpaX::JSON::parse_json(q${"test":"1.25"}$);
is($data->{test}, '1.25', '1.25');

$data = MarpaX::JSON::parse_json(q${"test":"1.25e4"}$);
is($data->{test}, '1.25e4', '1.25e4');

$data = MarpaX::JSON::parse_json(q$[]$);
is_deeply($data, [], '[]');

$data = MarpaX::JSON::parse_json(<<'JSON');
[
      {
         "precision": "zip",
         "Latitude":  37.7668,
         "Longitude": -122.3959,
         "Address":   "",
         "City":      "SAN FRANCISCO",
         "State":     "CA",
         "Zip":       "94107",
         "Country":   "US"
      },
      {
         "precision": "zip",
         "Latitude":  37.371991,
         "Longitude": -122.026020,
         "Address":   "",
         "City":      "SUNNYVALE",
         "State":     "CA",
         "Zip":       "94085",
         "Country":   "US"
      }
]
JSON
is_deeply($data, [
    { "precision"=>"zip", Latitude => "37.7668", Longitude=>"-122.3959",
      "Country" => "US", Zip => 94107, Address => '',
      City => "SAN FRANCISCO", State => 'CA' },
    { "precision" => "zip", Longitude => "-122.026020", Address => "",
      City => "SUNNYVALE", Country => "US", Latitude => "37.371991",
      Zip => 94085, State => "CA" }
], 'Geo data');

$data = MarpaX::JSON::parse_json(<<'JSON');
{
    "Image": {
        "Width":  800,
        "Height": 600,
        "Title":  "View from 15th Floor",
        "Thumbnail": {
            "Url":    "http://www.example.com/image/481989943",
            "Height": 125,
            "Width":  "100"
        },
        "IDs": [116, 943, 234, 38793]
    }
}
JSON
is_deeply($data, { 
    "Image" => {
        "Width" => 800, "Height" => 600,
        "Title" => "View from 15th Floor",
        "Thumbnail" => {
            "Url" => "http://www.example.com/image/481989943",
            "Height" => 125,
            "Width" => 100,
        },
        "IDs" => [ 116, 943, 234, 38793 ],
    }
}, 'is_deeply test');

$data = MarpaX::JSON::parse_json(<<'JSON');
{
    "source" : "<a href=\"http://janetter.net/\" rel=\"nofollow\">Janetter</a>",
    "entities" : {
        "user_mentions" : [ {
                "name" : "James Governor",
                "screen_name" : "moankchips",
                "indices" : [ 0, 10 ],
                "id_str" : "61233",
                "id" : 61233
            } ],
        "media" : [ ],
        "hashtags" : [ ],
        "urls" : [ ]
    },
    "in_reply_to_status_id_str" : "281400879465238529",
    "geo" : {
    },
    "id_str" : "281405942321532929",
    "in_reply_to_user_id" : 61233,
    "text" : "@monkchips Ouch. Some regrets are harsher than others.",
    "id" : 281405942321532929,
    "in_reply_to_status_id" : 281400879465238529,
    "created_at" : "Wed Dec 19 14:29:39 +0000 2012",
    "in_reply_to_screen_name" : "monkchips",
    "in_reply_to_user_id_str" : "61233",
    "user" : {
        "name" : "Sarah Bourne",
        "screen_name" : "sarahebourne",
        "protected" : false,
        "id_str" : "16010789",
        "profile_image_url_https" : "https://si0.twimg.com/profile_images/638441870/Snapshot-of-sb_normal.jpg",
        "id" : 16010789,
        "verified" : false
    }
}
JSON

$data = MarpaX::JSON::parse_json(<<'JSON');
{ "test":  "\u2603" }
JSON
is($data->{test}, "\x{2603}");

package MarpaX::JSON;

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

string       ::= lstring

:lexeme ~ lstring pause => before

lstring        ~ quote in_string quote
quote          ~ ["]
in_string      ~ in_string_char*
in_string_char  ~ [^"] | '\"'

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
    for ( my $pos = $re->read(\$string); $pos < $length; $pos = $re->resume()) {
       my ($start, $length) = $re->pause_span();
       my $value = substr $string, $start+1, $length-2;
       $value = decode_string($value) if -1 != index $value, '\\';
       $re->lexeme_read('lstring', $start, $length, $value) // die;
    }
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
