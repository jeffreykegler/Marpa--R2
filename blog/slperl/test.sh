PERL5LIB=../../r2/lib:../../r2/blib/arch:$PERL5LIB
cat test.in | while read f
do echo "==="
echo "In: $f"
echo "Found:"
echo "$f" | perl iterative.pl -q
done
