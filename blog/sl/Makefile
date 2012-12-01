
dummy:

test:
	PERL5LIB=../../r2/lib:../../r2/blib/arch:$$PERL5LIB perl sl.pl < p1000.in | \
	  diff - re1000.out || true

dsl1:
	PERL5LIB=../../r2/lib:../../r2/blib/arch:$$PERL5LIB perl dsl1.pl --demo

dsl3:
	PERL5LIB=../../r2/lib:../../r2/blib/arch:$$PERL5LIB perl dsl3.pl --demo

test_error:
	PERL5LIB=../../r2/lib:../../r2/blib/arch:$$PERL5LIB perl error.pl
