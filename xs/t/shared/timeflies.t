use 5.010;
use strict;
use warnings;
use lib 'tool/lib';
use lib 'ppshim';
use Marpa:::Test::Common;
Marpa::Test::Common::run(__FILE__, 'xs');
