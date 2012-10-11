for context in inline block
do for content in empty pcdata inline mixed block
do
cat <<EO_SH > acme-$context-$content.sh
cp default.cfg test.cfg
echo "ELE_acme is a FLO_$content included in GRP_$context" >> test.cfg
echo '<acme>-during-<span>-more inline stuff-<p>-new block-' |
  marpa_r2_html_fmt --no-added-tag --compile test.cfg
EO_SH
done
done
