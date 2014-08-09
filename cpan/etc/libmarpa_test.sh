if test -d "$1"
then :
else
   echo $1 is not a directory 1>&2
   exit 1
fi
if test -d engine/cf
then :
else
   (echo $1 is not a directory;
   echo Are you running this script in the cpan/ directory\?) 1>&2
   exit 1
fi
if test -r "$1/LIB_VERSION"
then :
else
   echo $1/LIBVERSION is not a readable file 1>&2
   exit 1
fi
(cd "$1"; make tar)
lib_version=`cat $1/LIB_VERSION`
tar_file=$1/libmarpa-$lib_version.tar.gz
(cd engine; tar -xvzf $tar_file)
(cd engine; test -d read_only && rm -rf read_only)
(cd engine; mv libmarpa-$lib_version read_only)
date > engine/read_only/stamp-h1
