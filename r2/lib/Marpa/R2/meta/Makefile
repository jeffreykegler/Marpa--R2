dummy:

doit:
	cp thin.pl thin-g1.pl
	perl -I../../../ -I../../../../blib/arch bnf_to_aoh.pl < Stuifzand.bnf | \
	  perl aoh_to_thin.pl > thin.pl
