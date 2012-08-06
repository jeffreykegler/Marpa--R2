for l in 10 100 500 1000 2000 3000
do echo $l
  perl balanced.pl -l $l
done
