BASE=$HOME/Desktop/stage/Marpa--R2/
for config in block-mixed block-inline block-pcdata
do
echo === $config ===
echo '<marpa>-during-<span>-more inline stuff-<p>-new block-' |
perl -I$BASE/$config/lib/perl5 $BASE/$config/bin/marpa_r2_html_fmt |
perl -I$BASE/block-inline/lib/perl5 -MMarpa::R2::HTML=html \
  -E '
    local $/=undef;
    my $text = ${html(\<STDIN>, { ":COMMENT" => sub {q{}} })};
    $text =~ s/^\s*\n//gxms;
    say $text
  '  | tee $config.html
done
