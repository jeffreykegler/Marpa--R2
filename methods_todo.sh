egrep '^=head2 ' r2/pod/Advanced/Thin.pod |
   egrep ' C<< ' | while read line; do \
   perl -n -E '
     s/.*([CGRBOTV])->new[(][)].*/marpa_\L$1\l_new/ and print;
     s/.*[\$]([cgrbotv])->([^\(]*).*/marpa_$1_$2/ and print;
   '
   done > /tmp/method.list
perl -n -E '
    m/::CLASS_LETTER.*['"'"']([cgrbotv])['"'"'][;]/ and $class = $1;
    m/[\(]qw[\(]([^ \)]*)[ \)]/ and say "marpa_$class" . "_$1";
     ' r2/xs/gp_generate.pl >> /tmp/method.list
sort -o /tmp/method.list /tmp/method.list
perl -n -E '
  s/{[^}]*}/{}/g;
  m/^[@]deftypefn [^ ]+ [^ ]+ ([^ ]+) / and say $1;
  m/^[@]deftypefunx? [^ ]+ ([^ ]+) / and say $1;
' r2/libmarpa/dev/api.texi | sort | comm -3 - /tmp/method.list
