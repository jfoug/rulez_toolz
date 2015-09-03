#!/usr/bin/perl
#
# single_rules_finder.pl   Part of rulez_toolz
#
##############################################
# these rules handled:
#   preprocessor (including \xHH)
#   proper de-duping of "[aeioua-z]" and \\ \[ \- \] in preprocessor
#   AN'str'      (including \xHH)
#   $N  ^N
#   TN
#   : l c C r f d u t { } [ ] DN
#   @X
#   @?C
#   all classes except ?o ?O ?y ?Y and ?0 to ?9
#   all number lengths except * + - a..k l m p
################################################
# still to do:
#   all classes and lengths.
#   reject rules (including keeping percentages for rules for stats)
#   reading rules from john.conf
#   code pages other than ISO-8859-1
#   > < _ ' -c -8 -s -p -u -U ->N -<N -: (rejection)
#   p P I  (hard stuff here!)
#   xNM
#   iNX
#   oNX
#   Q M XNMI
#   S V R L
#   vVNM  (V is numeric 0-9 ?)
#   sXY s?CY
#   !X  !?C
#   /X  /?C
#   =X  =?C
#   (X  (?C
#   )X  )?C
#   %NX %N?C
#   U
#   single stuff 1 2 +
#   \1..\9 \p0..\p9  \r
################################################
use String::Scanf;

my $dbg=0;                      # used for debugging. NORMALLY keep this at 0 -D# on command line can also set it.
if (@ARGV && substr($ARGV[0], 0, 2) eq "-D") { $dbg = substr($ARGV[0], 2, 1); print}
my %rulecnt=();                 # Rule and counts accumulated here.
my %rulejrejcnt=();             # number of words rejected for this rule.
my %cclass=(); load_classes();  # character classes. pre-define ALL of them
my %stats=();

foreach my $s (<STDIN>) {
	chomp $s;
	my @vals = split(":", $s);
	next if (check_rules(1, $vals[0], $vals[1], ':'));
	next if (check_rules(1, $vals[0], $vals[1], '[lcCutdrf{}]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d'));
	next if (check_rules(1, $vals[0], $vals[1], '@?D'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d [lcCutdrf{}]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?D [lcCutdrf{}]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d $[0-9]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d [lc] $[0-9]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d $[a-z]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d $[0-9]$[0-9]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d ^[0-9]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d ^[a-z]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d Az"12"'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d Az"123"'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d [lc]'));

	debug(1, "No rule found:  $s\n");
	$rulecnt{unk} += 1;
}

print "Each rule by count\n----------------------------\n";
# sort these, and print rules based upon max...min counts. All rules with 0 matches are NOT listed.
my $max_len = 0;
foreach my $rule (keys %rulecnt) {
	if (length($rule) > $max_len) { $max_len = length($rule); }
}
$max_len += 1;
foreach my $rule (reverse sort { $rulecnt{$a} <=> $rulecnt{$b} } keys %rulecnt) {
	if ($rulecnt{$rule} != 0) { printf("rule: %-${max_len}s found $rulecnt{$rule}\n", $rule); }
}
printf("Stats: ");
printf("Tested %d rule lines, ", $stats{check_rules});
printf("Producing %d rules, ", $stats{check_rule});
printf("Checking %d rule/words\n", $stats{rule_word});

# END OF program.

sub case { # turn john or JOHn into John
	my $w = lc $_[0];
	$w =~ s/\b(\w)/\U$1/g;
	return $w;
}
sub toggle_case {  # turn jOhN into JoHn
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
sub rev { # turn john into nhoj   (inlining reverse was having side effects so we function this)
	my $w = $_[0];
	$w = reverse $w;
	return $w;
}
sub purge {  #  purge out a set of characters. purge(test123john,"0123456789"); gives testjohn
	my ($w, $c) = @_;
	$w =~ s/[$c]*//g;
	return $w;
}
sub check_rule_word {
	my ($word, $crk, $rule) = @_;
	debug(2, "checking rule $rule against word $word for crack $crk\n");
	my @rc = split(undef, $rule);
	$stats{rule_word} += 1;
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
		if ($c eq '[') { if (length($word)) {$word = substr($word, 1);} next; }
		if ($c eq ']') { if (length($word)) {$word = substr($word, 0, length($word)-1);} next; }
		if ($c eq 'D') {
			my $pos = get_pos($rc[++$i], $word);
			if ($pos >= 0 && $pos <= length($word)) {
				$word = substr($word, 0,$pos-1).substr($word, $pos,length($word));
			}
		}
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
			$word=purge($word, $chars);
			next;
		}
		if ($c eq 'A') {
			my $pos = get_pos($rc[++$i], $word);
			if ($pos < 0) {next;}
			my $delim = $rc[++$i];
			debug(2,"delim=$delim\n");
			my $s = "";
			while ($rc[$i+1] ne $delim) {
				if ($rc[$i] eq '\\' && $rc[$i+1] eq "x") {
					# \xhh escape, replace with 'real' character
					$i += 2;
					my $s = $rc[++$i]; $s .= $rc[$i];
					($rc[$i]) = sscanf($s, "%X");
					$rc[$i] = chr($rc[$i]);
				}
				$s .= $rc[++$i];
			}
			++$i;
			substr($word, $pos, 0) = $s;
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
sub check_rule {
	my ($inp, $crk, $rule) = @_;
	$stats{check_rule} += 1;
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
sub esc_remove {
	my $w = $_[0];
	my $p = index($w, "\\");
	while ($p >= 0) {
		#print "w=$w p=$p ";
		if (substr($w,$p+1,1) eq "\\") {++$p;} # \\ so keep the first one intact
		$w = substr($w,0,$p).substr($w,$p+1);
		#print "now w=$w\n";
		$p = index($w, "\\", $p);
	}
	return $w;
}
sub get_items {
	my $s = $_[0];
	if (length($_[0]) < 3) {return ""; }
	my $chars_raw = esc_remove(substr($s, 1, length($s)-2));
	debug(2, "in get_items() request for $s chars_raw = $chars_raw \n");
	if (index($chars_raw, '-')==-1) {return $chars_raw;}
	my $chars = "";
	my @ch = split(undef, $chars_raw);
	# note, we do not check for some invalid ranges, like [-b] or [ab-] or [z-a]
	for (my $i = 0; $i < length($chars_raw); ++$i) {
		if ($ch[$i] != '-' && $ch[$i+1] != '-') {
			# \xhh escape, replace with 'real' character
			if ($ch[$i] eq '\\' && $ch[$i+1] eq "x") {
				$i += 2;
				my $s = $ch[++$i]; $s .= $ch[$i];
				($ch[$i]) = sscanf($s, "%X");
				$ch[$i] = chr($ch[$i]);
			}
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
# handle [] pre-processor. NOTE, recursive!
sub check_rules {
	my ($orig, $inp, $crk, $rules) = @_;
	if ($orig > 0) { $stats{check_rules} += 1; }
	debug(4, "Checking rule(s) $rules against $inp:$crk\n");
	my $pos = index($rules, '[');
	if ($pos == -1) { return check_rule($inp, $crk, $rules); }
	my $pos2 = index($rules, ']');
	if ($pos > $pos2)  { return check_rule($inp, $crk, $rules); }
	while ($pos < $pos2 && substr($rules, $pos2-1, 1) eq "\\") {
		$pos2 = index($rules, ']', $pos2+1);
	}
	if ($pos > $pos2)  { return check_rule($inp, $crk, $rules); }
	my $Chars = get_items(substr($rules, $pos, $pos2-$pos+1));
	debug(4, "item return is $Chars from $rules with sub=".substr($rules, $pos, $pos2-$pos+1)."\n");
	my @chars = split(undef, $Chars);
	foreach my $c (@chars) {
		my $s = $rules;
		debug(4, "before sub=$s\n");
		substr($s, $pos, $pos2-$pos+2) = $c;
		debug(4, "after sub=$s\n");
		if (check_rules(0, $inp, $crk, $s)) { return 1; }
	}
	return 0;
}

sub debug {
	my ($v, $m) = @_;
	if ($dbg < $v) { return; }
	print $m;
}

sub load_classes {
	my $c_all;  for ($i = 1;    $i < 255; ++$i) { $c_all  .= chr($i); }
	my $c_8all; for ($i = 0x80; $i < 255; ++$i) { $c_8all .= chr($i); }
	$cclass{z}=$c_all;
	$cclass{b}=$c_8all;
	$cclass{"\?"}="\?";
	$cclass{v}="aeiouAEIOU";
	$cclass{c}="bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ";
	$cclass{w}=" \t";
	$cclass{p}="\.,:;\'\?!`\"";
	$cclass{s}="\$%^&\*\(\)-_+=|\<\>\[\]\{\}#@/~";
	$cclass{l}="abcdefghijklmnopqrstuvwxyz";
	$cclass{u}=uc $cclass{l};
	$cclass{d}="0123456789";
	$cclass{a}=$cclass{l}.$cclass{u};
	$cclass{x}=$cclass{l}.$cclass{u}.$cclass{d};
	#$cclass{o}=? $cclass{y}=? not sure about control and 'valid'
	foreach my $c (split(undef,"bvcwpsludax")) {
		$C = uc $c;
		$cclass{$C}=purge($cclass{z}, $cclass{$c});
	}
}
