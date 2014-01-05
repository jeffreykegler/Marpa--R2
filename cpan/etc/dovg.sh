# Intended to be run from the cpan directory
(ls t/*.t; ls html/t/*.t) |
while read t
do
  echo === $t ===;
  echo $t | perl -Ilib -Iblib/arch \
    -E 'my $t = <STDIN>; chomp $t; use Test::Valgrind (file => $t, extra_supps => ["etc/my_suppressions"]);' 
done 2>&1 | tee dovg.log
