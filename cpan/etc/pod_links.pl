use 5.010;

use File::Spec;
use File::Find::Rule;
use Pod::Simple::SimpleTree;
use Data::Dumper;

my @pod_files = File::Find::Rule->file()->name( '*.pod' )->in('.');
# die join " ", @pod_files;

my %headers = ();

for my $pod_file (@pod_files) {
  my (undef, $dir, $file) = File::Spec->splitpath($pod_file);
  my @dirs = grep { $_; } File::Spec->splitdir($dir);
  my ($base, $ext) = split m/[.]/xms, $file;
  my $pod_name = join '::', qw(Marpa R2), @dirs, $base;
  # say $pod_name;
  my $tree = Pod::Simple::SimpleTree->new->parse_file($pod_file)->root;
  find_header($tree, $pod_name);
}

sub find_header {
     my ($subtree, $pod_name) = @_;
     if (ref $subtree eq 'ARRAY') {
         if (substr($subtree->[0], 0, 4) eq 'head') {
	    $headers{join ' ', $pod_name, $subtree->[2]} = 1;
	    # say $subtree->[2];
	 }
         if ($subtree->[0] eq 'L') {
	     my $hash = $subtree->[1];
	     return if not $hash->{type} eq 'pod';
	     $to_name = $hash->{to} // $pod_name;
	     return if not exists $hash->{section};
	    $links{join ' ', $to_name, $hash->{section}} = $pod_name;
	 }
       find_header($_, $pod_name) for @{$subtree};
     }
     return;
}

# say Dumper($tree);

# say "$_ H" for keys %headers;
# say "$_ L" for keys %links;
# exit 0;

for my $link (keys %links) {
    if (not exists $headers{$link})
    {
	my $pod_name = $links{$link};
        say "$pod_name unresolved link: $link"
    }
}
