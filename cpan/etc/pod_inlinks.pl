#!/usr/bin/perl
# Copyright 2014 Jeffrey Kegler
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

use 5.010;

use Pod::Simple::SimpleTree;
use Data::Dumper;

my $filename = shift;
my $tree = Pod::Simple::SimpleTree->new->parse_file($filename)->root;

my %headers = ();

sub find_header {
     my ($subtree) = @_;
     if (ref $subtree eq 'ARRAY') {
         if (substr($subtree->[0], 0, 4) eq 'head') {
	    $headers{$subtree->[2]} = 1;
	    # say $subtree->[2];
	 }
         if ($subtree->[0] eq 'L') {
	     my $hash = $subtree->[1];
	     return if not $hash->{type} eq 'pod';
	     return if exists $hash->{to};
	     return if not exists $hash->{section};
	     push @section_ref, $hash->{section};
	 }
       find_header($_) for @{$subtree};
     }
     return;
}

# say Dumper($tree);
find_header($tree);
for my $section_ref (@section_ref) {
    if (not exists $headers{$section_ref})
    {
        say STDERR "Unresolved internal section reference: $section_ref"
    }
}
