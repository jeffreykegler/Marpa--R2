ls t/*.t html/t/*.t |
while read t
do echo $t |
  perl -Ilib -Iblib/arch \
    -E 'my $t = <STDIN>; chomp $t; use Test::Valgrind (file => $t, extra_supps => ["my_suppressions"]);' 
done
