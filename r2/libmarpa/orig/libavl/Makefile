CFLAGS = -g -W -Wall -ansi -pedantic # enable many GCC warnings
LDFLAGS = -g

dummy:

avl-test: avl.o avl-test.o test.o

bst-test.c: bst.h test.h
avl-test.c: avl.h test.h
rb-test.c: rb.h test.h
tbst-test.c: tbst.h test.h
tavl-test.c: tavl.h test.h
trb-test.c: trb.h test.h
rtbst-test.c: rtbst.h test.h
rtavl-test.c: rtavl.h test.h
rtrb-test.c: rtrb.h test.h
pbst-test.c: pbst.h test.h
pavl-test.c: pavl.h test.h
prb-test.c: prb.h test.h

.PHONY: all 
.PHONY: docs info dvi eps txt png
.PHONY: programs sources
.PHONY: distdir dist check checksrc
.PHONY: texclean clean mostlyclean distclean maintainer-clean
