egrep '^=head2 ' r2/pod/Advanced/Thin.pod |
   egrep ' C<< ' | while read line; do \
   perl -n -E '
     s/.*([CGRBOTV])->new[(][)].*/marpa_\L$1\l_new/ and print;
     s/.*[\$]([cgrbotv])->([^\(]*).*/marpa_$1_$2/ and print;
   '
   done
perl -n -E '
    m/::CLASS_LETTER.*['"'"']([cgrbotv])['"'"'][;]/ and $class = $1;
    m/[\(]qw[\(]([^ ]*) / and say "marpa_$class" . "_$1";
     ' r2/xs/gp_generate.pl
