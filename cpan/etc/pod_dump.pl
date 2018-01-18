use 5.010001;

use Pod::Simple::SimpleTree;
use Data::Dumper;

print Dumper(Pod::Simple::SimpleTree->new->parse_file(shift)->root)
