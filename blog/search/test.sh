cat test.in | while read f
do echo "==="
echo "In: $f"
echo "Found:"
echo "$f" | perl search.pl
done
