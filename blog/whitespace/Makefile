
dummy:

test: synopsis comment prefix

synopsis:
	PERL5LIB=../../r2/lib:../../r2/blib/arch:$$PERL5LIB perl synopsis.pl --demo

comment:
	PERL5LIB=../../r2/lib:../../r2/blib/arch:$$PERL5LIB perl comment.pl --demo

prefix:
	PERL5LIB=../../r2/lib:../../r2/blib/arch:$$PERL5LIB perl prefix.pl --demo | \
	    diff - prefix.out

