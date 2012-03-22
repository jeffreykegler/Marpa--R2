TEX = etex # substitute tex if you lack etex
WEAVE_FLAGS =
#TANGLE_FLAGS = -l # put #line directives in source files
CFLAGS = -g -W -Wall -ansi -pedantic # enable many GCC warnings
LDFLAGS = -g

ALL_MAKEINFO_FLAGS = --number-sections $(MAKEINFO_FLAGS)

trees = $(wildcard *.tree)
eps_images = $(patsubst %.tree,%.eps,$(trees))
txt_images = $(patsubst %.tree,%.txt,$(trees))
png_images = $(patsubst %.tree,%.png,$(trees)) trav-circ.png trav-line.png
pdf_images = $(patsubst %.tree,%.pdf,$(trees)) trav-circ.pdf trav-line.pdf \
	cover.pdf

w_source = avl.w bst.w catalogue.w examples.w extra.w glossary.w	\
intro.w libavl.w pavl.w pbst.w prb.w preface.w rb.w references.w	\
rtavl.w rtbst.w rtrb.w search-alg.w table.w tavl.w tbst.w trb.w

testers = bst-test avl-test rb-test tbst-test tavl-test trb-test	\
rtbst-test rtavl-test rtrb-test pbst-test pavl-test prb-test
targets = $(testers) bin-ary-test bsts seq-test slr srch-test
translators = texitree texiweb
programs = $(targets) $(translators)

built_sources =					\
bst.c bst.h bst-test.c				\
avl.c avl.h avl-test.c				\
rb.c rb.h rb-test.c				\
tbst.c tbst.h tbst-test.c			\
tavl.c tavl.h tavl-test.c			\
trb.c trb.h trb-test.c				\
rtbst.c rtbst.h rtbst-test.c			\
rtavl.c rtavl.h rtavl-test.c			\
rtrb.c rtrb.h rtrb-test.c			\
pbst.c pbst.h pbst-test.c			\
pavl.c pavl.h pavl-test.c			\
prb.c prb.h prb-test.c				\
test.c test.h					\
bin-ary-test.c srch-test.c seq-test.c bsts.c

extra_dist = AUTHORS COPYING COPYING.DOC COPYING.LIB ChangeLog INSTALL	\
Makefile NEWS OUTLINE README ROADMAP THANKS TODO afm2c check-table	\
cover.eps eps2png epstopdf fdl.texi helvetica.afm helvetica.inc htmlpp	\
index.png libavl.info-[0-9] next.png padding.png prev.png skipback.png	\
skipfwd.png slr.c texinfo.tex texitree.c texiweb.c toc.png		\
trav-circ.eps trav-circ.sk trav-line.eps trav-line.sk trav-line.txt	\
up.png

dist_files = $(w_source) $(built_sources) $(trees) $(png_images)	\
$(pdf_images) libavl.info

all: docs programs
info: libavl.info
dvi: libavl.dvi
docs: libavl.dvi libavl.info libavl.text libavl.html libavl.ps libavl.pdf
eps: $(eps_images)
txt: $(txt_images)
png: $(png_images)
pdf: $(pdf_images)
programs: $(programs)
sources: $(built_sources)

bst-test: bst.o bst-test.o test.o
avl-test: avl.o avl-test.o test.o
rb-test: rb.o rb-test.o test.o
tbst-test: tbst.o tbst-test.o test.o
tavl-test: tavl.o tavl-test.o test.o
trb-test: trb.o trb-test.o test.o
rtbst-test: rtbst.o rtbst-test.o test.o
rtavl-test: rtavl.o rtavl-test.o test.o
rtrb-test: rtrb.o rtrb-test.o test.o
pbst-test: pbst.o pbst-test.o test.o
pavl-test: pavl.o pavl-test.o test.o
prb-test: prb.o prb-test.o test.o

bin-ary-test: bin-ary-test.o
bsts: bsts.o test.o
seq-test: seq-test.o

slr: slr.o
texitree: texitree.o
texiweb: texiweb.o

$(built_sources): texiweb
bst.c: bst.h
avl.c: avl.h
rb.c: rb.h
tbst.c: tbst.h
tavl.c: tavl.h
trb.c: trb.h
rtbst.c: rtbst.h
rtavl.c: rtavl.h
rtrb.c: rtrb.h
pbst.c: pbst.h
pavl.c: pavl.h
prb.c: prb.h

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

test.c: test.h
bsts.c: test.h

search-alg.w bst.w avl.w rb.w tbst.w tavl.w trb.w rtbst.w rtavl.w	\
rtrb.w pbst.w pavl.w prb.w:						\
	intro.w

bin-ary-test.c srch-test.c seq-test.c: search-alg.w
	./texiweb $(TANGLE_FLAGS) tangle libavl.w $@
bst-test.c bst.c bst.h bsts.c test.c test.h: bst.w
	./texiweb $(TANGLE_FLAGS) tangle libavl.w $@
avl-test.c avl.c avl.h: avl.w
	./texiweb $(TANGLE_FLAGS) tangle libavl.w $@
rb-test.c rb.c rb.h: rb.w
	./texiweb $(TANGLE_FLAGS) tangle libavl.w $@
tbst-test.c tbst.c tbst.h: tbst.w
	./texiweb $(TANGLE_FLAGS) tangle libavl.w $@
tavl-test.c tavl.c tavl.h: tavl.w
	./texiweb $(TANGLE_FLAGS) tangle libavl.w $@
trb-test.c trb.c trb.h: trb.w
	./texiweb $(TANGLE_FLAGS) tangle libavl.w $@
rtbst-test.c rtbst.c rtbst.h: rtbst.w
	./texiweb $(TANGLE_FLAGS) tangle libavl.w $@
rtavl-test.c rtavl.c rtavl.h: rtavl.w
	./texiweb $(TANGLE_FLAGS) tangle libavl.w $@
rtrb-test.c rtrb.c rtrb.h: rtrb.w
	./texiweb $(TANGLE_FLAGS) tangle libavl.w $@
pbst-test.c pbst.c pbst.h: pbst.w
	./texiweb $(TANGLE_FLAGS) tangle libavl.w $@
pavl-test.c pavl.c pavl.h: pavl.w
	./texiweb $(TANGLE_FLAGS) tangle libavl.w $@
prb-test.c prb.c prb.h: prb.w
	./texiweb $(TANGLE_FLAGS) tangle libavl.w $@

libavl.texi: $(w_source) texiweb
	./texiweb $(WEAVE_FLAGS) weave libavl.w $@
libavl.dvi: libavl.texi $(eps_images)
	TEX=$(TEX) texi2dvi --batch $<
libavl.ps: libavl.dvi
	dvips -P psfonts -o $@ $<
libavl.pdf: libavl.texi $(pdf_images)
	TEX=$(TEX) texi2pdf --batch --quiet $<
libavl.info: libavl.texi $(txt_images)
	makeinfo $(ALL_MAKEINFO_FLAGS) $<
libavl.text: libavl.texi $(txt_images)
	-makeinfo $(ALL_MAKEINFO_FLAGS) -D PLAINTEXT		\
		--no-headers --no-split $< -o $@
libavl.html: libavl.texi $(png_images) texiweb $(w_source)
	rm -rf $@ $@.t1 $@.t2
	makeinfo --html $(ALL_MAKEINFO_FLAGS) --output=$@.t1 $<
	./texiweb tangle --segments libavl.w $@.t1
	mkdir $@.t2
	./htmlpp $@.t1 $@.t2 .
	mv $@.t2 $@
	rm -rf $@.t1

%.eps: %.tree texitree
	./texitree ps < $< > $@

%.txt: %.tree texitree
	./texitree text < $< > $@

%.png: %.eps
	./eps2png $< $@ || touch $@

%.pdf: %.eps
	./epstopdf $< || touch $@

texitree: texitree.o
	$(CC) -lm $(LDFLAGS) $< $(LOADLIBS) $(LDLIBS) -o $@

version = 2.0.3
distdir: $(dist_files)
	rm -rf avl-$(version)
	mkdir avl-$(version)
	cp $(dist_files) $(extra_dist) avl-$(version)
dist: distdir
	tar chfz avl-$(version).tar.gz avl-$(version)
	rm -rf avl-$(version)

check: $(testers)
	@for d in $(testers); do		\
		echo "Checking $$d.";		\
		./check-table ./$$d || exit 1;	\
		echo;				\
	done

checksrc:
	-egrep -n '(FIXME|XXX)' *.w
	-./texiweb -u tangle libavl.w
	-./texiweb -ca weave libavl.w libavl.texi
	-grep -n '^@<Anonymous@> =' *.w

texclean:
	rm -f *.aux *.cp *.cps *.fn *.ky *.log *.pg *.toc *.tp *.vr *.hdr

clean: texclean
	rm -f *.ans
	rm -f libavl.texi libavl.ans libavl.text
	rm -rf libavl.html libavl.html.raw
	rm -f libavl.dvi libavl.ps libavl.pdf
	rm -f $(programs)
	rm -f $(eps_images) $(txt_images)
	rm -f *.o *.tmp
	rm -f a.out foo*

mostlyclean: clean

distclean: clean
	rm -f *~

maintainer-clean: distclean
	rm -f $(png_images) $(pdf_images) $(built_sources)
	rm -f libavl.info*

.PHONY: all 
.PHONY: docs info dvi eps txt png
.PHONY: programs sources
.PHONY: distdir dist check checksrc
.PHONY: texclean clean mostlyclean distclean maintainer-clean
