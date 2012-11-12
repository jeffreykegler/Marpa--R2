(cd libmarpa/dev; make install)
version=`libmarpa/stage/configure --version | sed -ne '1s/^marpa configure *//p'`
tar_file=libmarpa/stage/marpa-$version.tar.gz
if test -d libmarpa_dist && test libmarpa_dist/stamp-h1 -nt $tar_file;
then exit 0;
fi
rm -rf libmarpa_dist
mkdir libmarpa_dist.$$
(cd libmarpa_dist.$$; tar -xzf ../$tar_file)
mv libmarpa_dist.$$/marpa-$version libmarpa_dist
date > libmarpa_dist/stamp-h1
find libmarpa_dist -type f -print0 | xargs -0 chmod ugo-w
rmdir libmarpa_dist.$$

# same thing for the doc directory
tar_file=libmarpa/doc/marpa-doc-$version.tar.gz
if test -d libmarpa_doc_dist && test libmarpa_doc_dist/stamp-h1 -nt $tar_file;
then exit 0;
fi
rm -rf libmarpa_doc_dist
mkdir libmarpa_doc_dist.$$
(cd libmarpa_doc_dist.$$; tar -xzf ../$tar_file)
mv libmarpa_doc_dist.$$/marpa-doc-$version libmarpa_doc_dist
date > libmarpa_doc_dist/stamp-h1
find libmarpa_doc_dist -type f -print0 | xargs -0 chmod ugo-w
rmdir libmarpa_doc_dist.$$
