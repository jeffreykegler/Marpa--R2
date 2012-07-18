
all: libmarpa/configure
	cd libmarpa && sh configure
	cd libmarpa && make CFLAGS='-g -O2 -fno-inline -Wno-inline'

libmarpa/configure: ../libmarpa.tar
	tar -xvf ../libmarpa.tar
	version=`../stage/configure --version | sed -ne '1s/^marpa configure *//p'`; \
	  untar_dir=marpa-$$version ; \
	  mv $$untar_dir libmarpa
