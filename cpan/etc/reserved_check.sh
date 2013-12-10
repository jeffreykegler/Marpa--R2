for f in  marpa_ami.c marpa_avl.c marpa.c marpa_obs.c 
do
(cd libmarpa_build;
perl /home/jeffreykegler/perl5/perlbrew/perls/perl-5.10.1/bin/c2ast.pl \
  -DHAVE_CONFIG_H -I. \
  --cpp gcc --cpp -E --cppfile ./marpa.w  --progress --check reservedNames $f )
done
