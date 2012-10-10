BASE=../../r2/
for config in empty pcdata inline mixed
do
echo === $config ===
echo 'before tag<p>after tag' |
  perl -I$BASE/html/lib -I$BASE/lib -I$BASE/blib/arch $BASE/html/script/marpa_r2_html_fmt \
      --no-added-tag --compile g-body-$config.cfg |
  tee body-$config.html
done
