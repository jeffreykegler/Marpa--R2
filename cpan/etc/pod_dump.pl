use 5.010;

use Pod::Simple::SimpleTree;
use Data::Dumper;

print Dumper(Pod::Simple::SimpleTree->new->parse_file(shift)->root)
