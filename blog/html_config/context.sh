BASE=$HOME/Desktop/stage/Marpa--R2/
for config in inline-inline block-inline
do
echo === $config ===
config_base=$BASE/$config
echo '<p>before<marpa>-during-</marpa>after</p>' |
perl -I$config_base/lib/perl5 $config_base/bin/marpa_r2_html_fmt |
perl -I$config_base/lib/perl5 -MMarpa::R2::HTML=html \
  -E '
    local $/=undef;
    my $text = ${html(\<STDIN>, { ":COMMENT" => sub {q{}} })};
    $text =~ s/^\s*\n//gxms;
    say $text
  '  | tee $config-context.html
done
