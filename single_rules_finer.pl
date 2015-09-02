#!/usr/bin/perl
#
# single_rules_finder.pl   Part of rulez_toolz
#

my $dbg=0; # used for debugging. NORMALLY keep this at 0

my %rulecnt=(unk=>0); # Rule and counts accumulated here.

# character classes (pre define ALL of them).
my %cclass=(); load_classes();

foreach my $s (<STDIN>) {
	my @vals = split(":", $s);
	chomp $s;
	next if (check_rules($vals[0], $vals[1], '[:lcCutdrf{}]'));
	next if (check_rules($vals[0], $vals[1], '@?d'));
	next if (check_rules($vals[0], $vals[1], '@?D'));
	next if (check_rules($vals[0], $vals[1], '@?d [lcCutdrf{}]'));
	next if (check_rules($vals[0], $vals[1], '@?D [lcCutdrf{}]'));
	next if (check_rules($vals[0], $vals[1], '@?d $[0-9]'));
	next if (check_rules($vals[0], $vals[1], '@?d $[a-z]'));
	next if (check_rules($vals[0], $vals[1], '@?d $[0-9]$[0-9]'));
	next if (check_rules($vals[0], $vals[1], '@?d ^[0-9]'));
	next if (check_rules($vals[0], $vals[1], '@?d ^[a-z]'));
	next if (check_rules($vals[0], $vals[1], '@?d Az"12"'));
	next if (check_rules($vals[0], $vals[1], '@?d Az"123"'));
	next if (check_rules($vals[0], $vals[1], '@?d [lc]'));
	debug(1, "No rule found:  $s\n");
	$rulecnt{unk} += 1;
}

print "done checking, now printing counts found for each rule %rulecnt\n";
# sort these, and print rules based upon max...min counts. All rules with 0 matches are NOT listed.
foreach my $rule (reverse sort { $rulecnt{$a} <=> $rulecnt{$b} } keys %rulecnt) {
	if ($rulecnt{$rule} != 0) { printf("rule: %-10s found $rulecnt{$rule}\n", $rule); }
}
# END OF program.

sub case {
	my $w = lc $_[0];
	$w =~ s/\b(\w)/\U$1/g;
	return $w;
}
sub toggle_case {
	my @a = split(undef, $_[0]);
	my $w = "";
	foreach my $c (@a) {
		if (ord($c) >= ord('a') && ord($c) <= ord('z')) { $w .= uc $c; }
		elsif (ord($c) >= ord('A') && ord($c) <= ord('Z')) { $w .= lc $c; }
		else { $w .= $c; }
	}
#	debug(2, "toggle $_[0] -> $w\n");
	return $w;
}
sub rev {
	my $w = $_[0];
	$w = reverse $w;
	return $w;
}
sub check_rule_word {
	my ($word, $crk, $rule) = @_;
	debug(2, "checking rule $rule against word $word for crack $crk\n");
	my @rc = split(undef, $rule);
	for (my $i = 0; $i < scalar(@rc); ++$i) {
		my $c = $rc[$i];
		next if ($c eq ' ' || $c eq ':');
		if ($c eq 'l') { $word = lc $word; next; }
		if ($c eq 'u') { $word = uc $word; next; }
		if ($c eq 'c') { $word = case($word); next; }
		if ($c eq 'C') { $word = toggle_case(case($word)); next; }
		if ($c eq 't') { $word = toggle_case($word); next; }
		if ($c eq 'd') { $word = $word.$word; next; }
		if ($c eq 'r') { $word = rev($word); next; }
		if ($c eq 'f') { $word = $word.rev($word); next; }
		if ($c eq '$') { $word .= $rc[++$i]; next; }
		if ($c eq '^') { $word = $rc[++$i].$word; next; }
		if ($c eq '{') { $word = rotl($word); next; }
		if ($c eq '}') { $word = rotr($word); next; }
		if ($c eq 'T') {
			my $pos = get_pos($rc[++$i], $word);
			if ($pos >= 0) {
				my $c = substr($word, $pos, 1);
				if (ord($c) >= ord('a') && ord($c) <= ord('z')) { $c .= uc $c; }
				elsif (ord($c) >= ord('A') && ord($c) <= ord('Z')) { $w .= lc $c; }
				substr($word, $pos, 1) = $c;
			}
			$word = rotr($word); next; }
		if ($c eq '@') {
			my $chars = "";
			my $prg = '@'.$rc[$i];
			if ($rc[++$i] eq "?") { $chars = $cclass{$rc[++$i]}; $prg .= $rc[$i]; }
			else { $chars = $rc[$i]; }
			#debug(2, "before purge $prg  $word  ");
			$word=purge($word, $chars);
			#debug(2, "after = $word\n");
			next;
		}
	}
	if ($word eq $crk) { return 1;}
	return 0;
}
sub rotl {
	my $w = $_[0];
	$w = substr($w, 1, length($w)).substr($w, 0, 1);
	return $w;
}
sub rotr {
	my $w = $_[0];
	$w = substr($w, length($w)-1, 1).substr($w, 0, length($w)-1);
	return $w;
}
sub get_pos {
#0...9	for 0...9
#A...Z	for 10...35
#*	for max_length
#-	for (max_length - 1)
#+	for (max_length + 1)
#a...k	user-defined numeric variables (with the "v" command)
#l	initial or updated word's length (updated whenever "v" is used)
#m	initial or memorized word's last character position
#p	position of the character last found with the "/" or "%" commands
#z	"infinite" position or length (beyond end of word)
	my ($p, $w) = @_;
	if (ord($p) >= ord("0") && ord($p) <= ord('9')) {$p = ord($p)-ord('0');}
	elsif (ord($p) >= ord("A") && ord($p) <= ord('Z')) {$p = ord($p)-ord('A')+10;}
#	elsif ($p eq '*') {} elsif ($p eq '-') {} elsif ($p eq '+') {} elsif ($p eq 'a...k') {}
	elsif ($p eq 'z') {$p = length($w); }
	if ($p > length($w)) { return -1; }
	return $p;
}
sub purge {
	my ($w, $c) = @_;
	$w =~ s/[$c]*//g;
	return $w;
}
sub check_rule {
	my ($inp, $crk, $rule) = @_;
	my @rc = split(undef, $rule);
	my @words = ($inp, split(/[\-_@\. ;,?\"\'\[\]+=~!@#\$%^&*\(\)\/\\{}]/, $inp));
	my %hash   = map { $_ => 1 } @words;
	my @words = keys %hash;
	foreach my $word (@words) {
		if (check_rule_word($word, $crk, $rule)) {
			debug(2, "found rule = $rule   $inp  $crk\n");
			$rulecnt{$rule} += 1;
			return 1;
		}
	}
	return 0;
}
sub get_items {
	if (length($_[0]) < 3) {return ""; }
	my $chars_raw = substr(@_[0], 1, length($_[0])-2);
#	debug(2, "in get_items() request for $_[0] items_raw = $items_raw \n");
	if (index($chars_raw, '-')==-1) {return $chars_raw;}
	my $chars = "";
	my @ch = split(undef, $chars_raw);
	# note, we do not check for some invalid ranges, like [-b] or [ab-] or [z-a]
	for (my $i = 0; $i < length($chars_raw); ++$i) {
		if ($ch[$i] != '-' && $ch[$i+1] != '-') {
			$chars .= $ch[$i];
			next;
		}
		for (my $c = $ch[$i]; $c < $ch[$i+2]; ++$c) {
			$chars .= $c;
		}
		$i += 2;
	}
	return $chars;
}
# handle [] pre-processor. NOTE, recursive!  NOTE2, does not handle \[ or \] escapes, BEWARE
sub check_rules {
	my ($inp, $crk, $rules) = @_;
	debug(4, "Checking rule(s) $rules against $inp:$crk\n");
	my $pos = index($rules, '[');
	if ($pos == -1) { return check_rule($inp, $crk, $rules); }
	my $pos2 = index($rules, ']');
	if ($pos > $pos2)  { return check_rule($inp, $crk, $rules); }
	my $Chars = get_items(substr($rules, $pos, $pos2-$pos+1));
	my @chars = split(undef, $Chars);
	foreach my $c (@chars) {
		my $s = $rules;
		debug(4, "before sub=$s\n");
		substr($s, $pos, $pos2-$pos+2) = $c;
		debug(4, "after sub=$s\n");
		if (check_rules($inp, $crk, $s)) { return 1; }
	}
	return 0;
}

sub debug {
	my ($v, $m) = @_;
	if ($dbg < $v) { return; }
	print $m;
}

sub load_classes {
	my $c_all;  for ($i = 1;    $i < 255; ++$i) { $c .= chr($i); }
	my $c_8all; for ($i = 0x80; $i < 255; ++$i) { $c .= chr($i); }
	$cclass{z}=$c_all;
	$cclass{b}=$c_8all;
	$cclass{"\?"}="\?";
	$cclass{v}="aeiouAEIOU";
	$cclass{c}="bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ";
	$cclass{w}=" \t";
	$cclass{p}=".,:;'?!`\"";
	$cclass{s}="\$%^&*()-_+=|\<>[]{}#@/~";
	$cclass{l}="abcdefghijklmnopqrstuvwxyz";
	$cclass{u}=uc $cclass{l};
	$cclass{d}="0123456789";
	$cclass{a}=$cclass{l}.$cclass{u};
	$cclass{x}=$cclass{l}.$cclass{u}.$cclass{d};
	#$cclass{o}=? $cclass{y}=? not sure about control and 'valid'
	$cclass{B}=purge($cclass{z}, $cclass{b});
	$cclass{V}=purge($cclass{z}, $cclass{v});
	$cclass{C}=purge($cclass{z}, $cclass{c});
	$cclass{W}=purge($cclass{z}, $cclass{w});
	$cclass{P}=purge($cclass{z}, $cclass{p});
	$cclass{S}=purge($cclass{z}, $cclass{s});
	$cclass{L}=purge($cclass{z}, $cclass{l});
	$cclass{U}=purge($cclass{z}, $cclass{u});
	$cclass{D}=purge($cclass{z}, $cclass{d});
	$cclass{A}=purge($cclass{z}, $cclass{a});
	$cclass{X}=purge($cclass{z}, $cclass{x});
}