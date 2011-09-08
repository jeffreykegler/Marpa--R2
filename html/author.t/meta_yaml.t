#!perl
# This software is copyright (c) 2011 by Jeffrey Kegler
# This is free software; you can redistribute it and/or modify it
# under the same terms as the Perl 5 programming language system
# itself.

use 5.010;
use strict;
use warnings;

use Test::More;
use Test::CPAN::Meta;
Test::CPAN::Meta::meta_yaml_ok();
