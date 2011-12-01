#!perl

use 5.010;

while (my $line = <STDIN>) {
    if ($line =~ /[@]deftypefun/xms)
    {
	my $def = q{};
        while ($line =~ / [@] \s* \z /xms) {
	    $def .= $line;
	    $def =~ s/ [@] \s* \z//xms;
	    $line = <STDIN>;
	}
	$def .= $line;
	$def =~ s/\A \s* [@] deftypefun \s* //xms;
	$def =~ s/ [@]var[{] ([^}]*) [}]/$1/xmsg;
	$def =~ s/\s+/ /xmsg;
	$def =~ s/\s \z/;/xmsg;
	say $def;
    }
}
