BASE=../../r2/
for config in inline-inline block-empty block-pcdata block-inline block-mixed
do
echo === $config ===
echo '<marpa>-during-<span>-more inline stuff-<p>-new block-' |
  perl -I$BASE/html/lib -I$BASE/lib -I$BASE/blib/arch $BASE/html/script/marpa_r2_html_fmt \
      --no-added-tag --compile g-$config.cfg |
  tee $config.html
done
