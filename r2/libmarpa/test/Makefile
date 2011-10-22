
all:
	(cd lib; sh ../../dist/configure)
	(cd lib; make CFLAGS='-g -O2 -fno-inline -Wno-inline')
	(cd build; sh ../dev/configure)
	(cd build; make)
