# This software is copyright (c) 2011 by Jeffrey Kegler
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

package Marpa::HTML::Test;
use 5.010;
use strict;
use warnings;

Marpa::exception('Test::More not loaded')
    if not defined &Test::More::is;

BEGIN {
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    eval 'use Test::Differences';
    ## use critic
} ## end BEGIN
use Data::Dumper;

## no critic (Subroutines::RequireArgUnpacking)
sub Marpa::HTML::Test::is {
## use critic
    goto &Test::Differences::eq_or_diff
        if defined &Test::Differences::eq_or_diff && @_ > 1;
    @_ = map { ref $_ ? Data::Dumper::Dumper(@_) : $_ } @_;
    goto &Test::More::is;
} ## end sub Marpa::HTML::Test::is

1;

