cd html
PERL5LIB=lib:../lib:../devlib/xsshim:../blib/arch:$PERL5LIB
prove --verbose xt
prove t
