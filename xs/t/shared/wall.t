#!perl

use 5.010;
use strict;
use warnings;

# pperl lib is not needed by all tests,
# but it is easiest to keep all the shared/*.t files
# identical
use lib 'pperl';
use lib 'ppshim';
use lib 'tool/lib';
use Marpa::Test::Common;
Marpa::Test::Common::run( __FILE__);
