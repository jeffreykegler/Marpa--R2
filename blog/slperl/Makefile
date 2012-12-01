dummy:

test:
	sh test.sh | diff - test.out

test1:
	echo -n 'Input: '; sed -e 1q test.in
	sed -e 1q test.in | \
	  PERL5LIB=../../r2/lib:../../r2/blib/arch:$$PERL5LIB perl iterative.pl -q
