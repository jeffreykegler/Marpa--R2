#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Marpa::HTML;
use WWW::Mechanize;

my $arg = shift;
say $arg;
my $mech = WWW::Mechanize->new( autocheck => 1 );
$mech->get( $arg );
my $document = $mech->content;
undef $mech;

my @result;
my $keep_me = sub { push @result, Marpa::HTML::original()  };

my $value = Marpa::HTML->new(
    {   handlers => [
            [   ':PI' => $keep_me ],
            [   ':COMMENT' => $keep_me ],
            [   'font' => $keep_me ],
        ],
    }
)->parse( \$document );

say join "\n", @result;
