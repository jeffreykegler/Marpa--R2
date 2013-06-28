use 5.010;
use Test::More;
use Test::Exception;
use lib '.';
use lib '../../cpan/lib';
use lib '../../cpan/blib/arch';
use lib 'lib';
use Marpa::R2 2.060_002;
use MarpaX::JSON;

say STDERR "Using Marpa::R2 ", $Marpa::R2::VERSION;

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

done_testing();
