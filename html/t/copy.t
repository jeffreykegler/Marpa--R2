use 5.010;
use strict;
use warnings;

use lib 'lib';
use Test::More tests => 3;

Test::More::use_ok('HTML::PullParser');
Test::More::use_ok('Marpa::HTML');

use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw(open close);

my $document;
{
    local $RS = undef;
    open my $fh, q{<:utf8}, 't/test.html';
    $document = <$fh>;
    close $fh
};

my $value = Marpa::HTML::html( \$document );

Test::More::is( ${$value}, $document, 'Straight copy using defaults' );
