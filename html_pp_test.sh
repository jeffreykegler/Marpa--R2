cd html
PERL5LIB=lib:../lib:../devlib/ppshim:../blib/arch:$PERL5LIB
prove --verbose xt
prove t
