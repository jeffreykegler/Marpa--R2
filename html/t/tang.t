#!perl
# This software is copyright (c) 2011 by Jeffrey Kegler
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

use 5.010;
use strict;
use warnings;

use lib 'lib';
use Test::More tests => 4;
Test::More::use_ok('HTML::PullParser');
Test::More::use_ok('Marpa::HTML::Test');
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
    close $fh;
};

my $no_tang_document;
{
    local $RS = undef;
    open my $fh, q{<:utf8}, 't/no_tang.html';
    $no_tang_document = <$fh>;
    close $fh;
};

my $value = Marpa::HTML::html(
    \$document,
    {   '.ktang' => sub { return q{}; }
    }
);

Marpa::HTML::Test::is( ${$value}, $no_tang_document, 'remove kTang class' );
