
all: libmarpa/libmarpa.la

libmarpa/libmarpa.la: libmarpa/stamp
	cd libmarpa && sh configure
	cd libmarpa && make CFLAGS='-g -O2 -fno-inline -Wno-inline'

libmarpa/stamp: ../libmarpa.tar
	test -d libmarpa && rm -rf libmarpa
	tar -xvf ../libmarpa.tar
	version=`../stage/configure --version | sed -ne '1s/^marpa configure *//p'`; \
	  untar_dir=marpa-$$version ; \
	  mv $$untar_dir libmarpa
	touch libmarpa/stamp
