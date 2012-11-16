cat test.in | while read f
do echo "==="
echo "In: $f"
echo "Found:"
echo "$f" | perl incremental.pl -q
done
