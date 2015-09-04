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
#   all number lengths except * + - a..k p
#   sXY s?CY
#   S V R L
#   xNM iNX oNX
#   Q M XNMI
#   reject rules (including keeping percentages for rules for stats)
#   !X  !?C  (rejection)
#   /X  /?C  (rejection)
#   =X  =?C  (rejection)
#   (X  (?C  (rejection)
#   )X  )?C  (rejection)
#   %NX %N?C (rejection)
#   >N <N _N (rejection word length)
#   'N        (truncate)
################################################
# still to do:
#   all classes and lengths.
#   reading rules from john.conf
#   code pages other than ISO-8859-1
#   p P I  (hard stuff here!)
#   vVNM  (V is numeric 0-9 ?)
#   -c -8 -s -p -u -U ->N -<N -: (rejection rules)
#   U
#   single stuff 1 2 +
#   \1..\9 \p0..\p9  \r
################################################
use String::Scanf;

my $dbg=0;                      # used for debugging. NORMALLY keep this at 0 -D# on command line can also set it.
if (@ARGV && substr($ARGV[0], 0, 2) eq "-D") { $dbg = substr($ARGV[0], 2, 1); print}
my %rulecnt=();                 # Rule and counts accumulated here.
my %rulejrejcnt=();             # number of words rejected for this rule.
my %ruletrycnt=();              # number of words tested by this rule.
my %cclass=(); load_classes();  # character classes. pre-define ALL of them
my %stats=();
my $M;                          # memorized word.
my $rejected;

foreach my $s (<STDIN>) {
	chomp $s;
	my @vals = split(":", $s);
#next if (check_rules(1, $vals[0], $vals[1], '-[:c] (?\p1[za] \p1[lc] $! <- Az"!!"'));
#exit(0);


	next if (check_rules(1, $vals[0], $vals[1], '>4 [:lcCutdrf{}]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d >4'));
	next if (check_rules(1, $vals[0], $vals[1], '@?D >4'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d >4 M [lcCutdrf{}] Q'));
	next if (check_rules(1, $vals[0], $vals[1], '@?D >4 M [lcCutdrf{}] Q'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d >3 Az"12"'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d >3 Az"123"'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d >3 $[0-9]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d >3 M [lc] Q $[0-9]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d >3 $[a-z]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d >3 ^[0-9]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d >3 ^[a-z]'));
	next if (check_rules(1, $vals[0], $vals[1], '@?d >3 $[0-9]$[0-9]'));

	# the entire ruleset from jumbo john.conf file.
	next if (check_rules(1, $vals[0], $vals[1], ':'));
	next if (check_rules(1, $vals[0], $vals[1], '-s x**'));
	next if (check_rules(1, $vals[0], $vals[1], '-c (?a c Q'));
	next if (check_rules(1, $vals[0], $vals[1], '-c l Q'));
	next if (check_rules(1, $vals[0], $vals[1], '-s-c x** /?u l'));
	next if (check_rules(1, $vals[0], $vals[1], '-<6 >6 \'6'));
	next if (check_rules(1, $vals[0], $vals[1], '-<7 >7 \'7 l'));
	next if (check_rules(1, $vals[0], $vals[1], '-<6 -c >6 \'6 /?u l'));
	next if (check_rules(1, $vals[0], $vals[1], '-<5 >5 \'5'));
	next if (check_rules(1, $vals[0], $vals[1], '/?d @?d >4'));
	next if (check_rules(1, $vals[0], $vals[1], '/?d @?d M @?A Q >4'));
	next if (check_rules(1, $vals[0], $vals[1], '/?d @?d >4 M [lc] Q'));
	next if (check_rules(1, $vals[0], $vals[1], '/?d @?d M @?A Q >4 M [lc] Q'));
	next if (check_rules(1, $vals[0], $vals[1], '@?D Q >4'));
	next if (check_rules(1, $vals[0], $vals[1], '/?d @?d >3 <* $[0-9] Q'));
	next if (check_rules(1, $vals[0], $vals[1], '/?d @?d M >3 <* [lc] Q $[0-9] Q'));
	next if (check_rules(1, $vals[0], $vals[1], '/?d @?d >3 <- Az"12" Q'));
	next if (check_rules(1, $vals[0], $vals[1], '/?d @?d M >3 <- [lc] Q Az"12"'));
	next if (check_rules(1, $vals[0], $vals[1], '/?d @?d >3 Az"123" Q <+'));
	next if (check_rules(1, $vals[0], $vals[1], '/?d @?d M >3 [lc] Q Az"123" <+'));
	next if (check_rules(1, $vals[0], $vals[1], '/?d @?d >2 d Q <+'));
	next if (check_rules(1, $vals[0], $vals[1], '/?d @?d >2 M [lc] Q d<+'));
	next if (check_rules(1, $vals[0], $vals[1], '(?a )?d /?d \'p Xpz0'));
	next if (check_rules(1, $vals[0], $vals[1], ')?a (?d /?a \'p Xpz0'));
	next if (check_rules(1, $vals[0], $vals[1], '<* d'));
	next if (check_rules(1, $vals[0], $vals[1], 'r c'));
	next if (check_rules(1, $vals[0], $vals[1], '-c <* (?a d c'));
	next if (check_rules(1, $vals[0], $vals[1], '-<5 -c >5 \'5 /?u l'));
	next if (check_rules(1, $vals[0], $vals[1], '-c u Q'));
	next if (check_rules(1, $vals[0], $vals[1], '-c )?a r l'));
	next if (check_rules(1, $vals[0], $vals[1], '-[:c] <* !?A \p1[lc] p'));
	next if (check_rules(1, $vals[0], $vals[1], '-c <* c Q d'));
	next if (check_rules(1, $vals[0], $vals[1], '-<7 -c >7 \'7 /?u'));
	next if (check_rules(1, $vals[0], $vals[1], '-<4 >4 \'4 l'));
	next if (check_rules(1, $vals[0], $vals[1], '-c <+ (?l c r'));
	next if (check_rules(1, $vals[0], $vals[1], '-c <+ )?l l Tm'));
	next if (check_rules(1, $vals[0], $vals[1], '-<3 >3 \'3'));
	next if (check_rules(1, $vals[0], $vals[1], '-<4 -c >4 \'4 /?u'));
	next if (check_rules(1, $vals[0], $vals[1], '-<3 -c >3 \'3 /?u l'));
	next if (check_rules(1, $vals[0], $vals[1], '-c u Q r'));
	next if (check_rules(1, $vals[0], $vals[1], '<* d M \'l f Q'));
	next if (check_rules(1, $vals[0], $vals[1], '-c <* l Q d M \'l f Q'));
	next if (check_rules(1, $vals[0], $vals[1], '>[2-8] x1\1'));
	next if (check_rules(1, $vals[0], $vals[1], '>9 \['));
	next if (check_rules(1, $vals[0], $vals[1], '>[3-9] x2\p[2-8]'));
	next if (check_rules(1, $vals[0], $vals[1], '>[4-9] x3\p[2-7]'));
	next if (check_rules(1, $vals[0], $vals[1], '-c >[2-8] x1\1 /?u l'));
	next if (check_rules(1, $vals[0], $vals[1], '-c >9 \[ /?u l'));
	next if (check_rules(1, $vals[0], $vals[1], '-c >[3-9] x2\p[2-8] /?u l'));
	next if (check_rules(1, $vals[0], $vals[1], '-c >[4-9] x3\p[2-7] /?u l'));
	next if (check_rules(1, $vals[0], $vals[1], '<* l $[1-9!0a-rt-z"-/:-@\[-`{-~]'));
	next if (check_rules(1, $vals[0], $vals[1], '-c <* (?a c $[1-9!0a-rt-z"-/:-@\[-`{-~]'));
	next if (check_rules(1, $vals[0], $vals[1], '-[:c] <* !?A (?\p1[za] \p1[lc] $s M \'l p Q X0z0 \'l $s'));
	next if (check_rules(1, $vals[0], $vals[1], '-[:c] <* /?A (?\p1[za] \p1[lc] $s'));
	next if (check_rules(1, $vals[0], $vals[1], '<* l r $[1-9!]'));
	next if (check_rules(1, $vals[0], $vals[1], '-c <* /?a u $[1-9!]'));
#	next if (check_rules(1, $vals[0], $vals[1], '-[:c] <- (?\p1[za] \p1[lc] Az"\'s"'));
#	next if (check_rules(1, $vals[0], $vals[1], '-[:c] <- (?\p1[za] \p1[lc] Az"!!"'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] (?\p1[za] \p1[lc] $! <- Az"!!"'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] /?v @?v >2 (?\p1[za] \p1[lc]'));
	#next if (check_rules(1, $vals[0], $vals[1], '/?v @?v >2 <* d'));
	#next if (check_rules(1, $vals[0], $vals[1], '<* l [PI]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c <* l [PI] (?a c'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] <* (?\p1[za] \p1[lc] )y omi $e'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] <* (?\p1[za] \p1[lc] )e \] )i val1 oay'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /[aelos] s\0\p[4310$] (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /a /[elos] sa4 s\0\p[310$] (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /e /[los] se3 s\0\p[10$] (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /l /[os] sl1 s\0\p[0$] (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /o /s so0 ss$ (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /a /e /[los] sa4 se3 s\0\p[10$] (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /a /l /[os] sa4 sl1 s\0\p[0$] (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /a /o /s sa4 so0 ss$ (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /e /l /[os] se3 sl1 s\0\p[0$] (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /[el] /o /s s\0\p[31] so0 ss$ (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /a /e /l /[os] sa4 se3 sl1 s\0\p[0$] (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /a /[el] /o /s sa4 s\0\p[31] so0 ss$ (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /e /l /o /s se3 sl1 so0 ss$ (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] l /a /e /l /o /s sa4 se3 sl1 so0 ss$ (?\p1[za] \p1[:c]'));
	#next if (check_rules(1, $vals[0], $vals[1], 'l ^[1a-z2-90]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c l Q ^[A-Z]'));
	#next if (check_rules(1, $vals[0], $vals[1], '^[A-Z]'));
	#next if (check_rules(1, $vals[0], $vals[1], 'l ^["-/:-@\[-`{-~]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] <9 (?a \p1[lc] A0"[tT]he"'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] <9 (?a \p1[lc] A0"[aA]my"'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] <9 (?a \p1[lc] A0"[mdMD]r"'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] <9 (?a \p1[lc] A0"[mdMD]r."'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] <9 (?a \p1[lc] A0"__"'));
	#next if (check_rules(1, $vals[0], $vals[1], '<- !?A l p ^[240-9]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-p-c (?a 2 (?a c 1 [cl]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-p 1 <- $[ _\-] + l'));
	#next if (check_rules(1, $vals[0], $vals[1], '-p-c 1 <- (?a c $[ _\-] 2 l'));
	#next if (check_rules(1, $vals[0], $vals[1], '-p-c 1 <- l $[ _\-] 2 (?a c'));
	#next if (check_rules(1, $vals[0], $vals[1], '-p-c 1 <- (?a c $[ _\-] 2 (?a c'));
	#next if (check_rules(1, $vals[0], $vals[1], '-p-[c:] 1 \p1[ur] 2 l'));
	#next if (check_rules(1, $vals[0], $vals[1], '-p-c 2 (?a c 1 [ur]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-p-[c:] 1 l 2 \p1[ur]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-p-c 1 (?a c 2 [ur]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] (?a \p1[lc] [{}]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] (?a \p1[lc] [{}] \0'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c <+ )?u l Tm'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c T0 Q M c Q l Q u Q C Q X0z0 \'l'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c T[1-9A-E] Q M l Tm Q C Q u Q l Q c Q X0z0 \'l'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c l Q T[1-9A-E] Q M T\0 Q l Tm Q C Q u Q X0z0 \'l'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c >2 <G %2?a [lu] T0 M T2 T4 T6 T8 TA TC TE Q M l Tm Q X0z0 \'l'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c >2 /?l /?u t Q M c Q C Q l Tm Q X0z0 \'l'));
	#next if (check_rules(1, $vals[0], $vals[1], '>[2-8] D\p[1-7]'));
	#next if (check_rules(1, $vals[0], $vals[1], '>[8-9A-E] D\1'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c /?u >[2-8] D\p[1-7] l'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c /?u >[8-9A-E] D\1 l'));
	#next if (check_rules(1, $vals[0], $vals[1], '=1?a \[ M c Q'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c (?a >[1-9A-E] D\1 c'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] >3 (?a \p1[lc] i[12].'));
	#next if (check_rules(1, $vals[0], $vals[1], '<- l Az"[190][0-9]"'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c <- (?a c Az"[190][0-9]"'));
	#next if (check_rules(1, $vals[0], $vals[1], '<- l Az"[782][0-9]"'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c <- (?a c Az"[782][0-9]"'));
	#next if (check_rules(1, $vals[0], $vals[1], '<* l $[A-Z]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c <* (?a c $[A-Z]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c u /I sIi'));
	#next if (check_rules(1, $vals[0], $vals[1], '%2?a C Q'));
	#next if (check_rules(1, $vals[0], $vals[1], '/?A S Q'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c /?v V Q'));
	#next if (check_rules(1, $vals[0], $vals[1], ':[RL] Q'));
	#next if (check_rules(1, $vals[0], $vals[1], 'l Q [RL]'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c (?a c Q [RL]'));
	#next if (check_rules(1, $vals[0], $vals[1], ':[RL] \0 Q'));
	#next if (check_rules(1, $vals[0], $vals[1], '<- l ^[1!@#$%^&*\-=_+.?|:\'"] $\1'));
	#next if (check_rules(1, $vals[0], $vals[1], '<- l ^[({[<] $\p[)}\]>]'));
	#next if (check_rules(1, $vals[0], $vals[1], '<- l Az"[63-5][0-9]"'));
	#next if (check_rules(1, $vals[0], $vals[1], '-c <- (?a c Az"[63-5][0-9]"'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] (?a \p1[lc] Az"007" <+'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] (?a \p1[lc] Az"123" <+'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] (?a \p1[lc] Az"[0-9]\0\0" <+'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] (?a \p1[lc] Az"1234" <+'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] (?a \p1[lc] Az"[0-9]\0\0\0" <+'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] (?a \p1[lc] Az"12345" <+'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] (?a \p1[lc] Az"[0-9]\0\0\0\0" <+'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] (?a \p1[lc] Az"123456" <+'));
	#next if (check_rules(1, $vals[0], $vals[1], '-[:c] (?a \p1[lc] Az"[0-9]\0\0\0\0\0" <+'));
	#next if (check_rules(1, $vals[0], $vals[1], 'l Az"19[7-96-0]" <+ >-'));
	#next if (check_rules(1, $vals[0], $vals[1], 'l Az"20[01]" <+ >-'));
	#next if (check_rules(1, $vals[0], $vals[1], 'l Az"19[7-9][0-9]" <+'));
	#next if (check_rules(1, $vals[0], $vals[1], 'l Az"20[01][0-9]" <+'));
	#next if (check_rules(1, $vals[0], $vals[1], 'l Az"19[6-0][9-0]" <+'));

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
	if ($rulecnt{$rule} != 0) { printf("rule: %-${max_len}s found $rulecnt{$rule}  while testing $ruletrycnt{$rule} words, rejecting ".($rulerejcnt{$rule}+0)." of them\n", $rule); }
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
sub purge {  #  purge out a set of characters. purge("test123john","0123456789"); gives testjohn
	my ($w, $c) = @_;
	$w =~ s/[$c]*//g;
	return $w;
}
sub replace_chars {
	my ($w, $ch, $chars) = @_;
	$w =~ s/[$chars]/$ch/g;
	return $w;
}
sub shift_case { # S	shift case: "Crack96" -> "cRACK(^"
	my ($w) = @_;
	$w =~ tr/A-Za-z0-9)!@#$%^&*(\-_=+\[{\]};:'",<.>\/?/a-zA-Z)!@#$%^&*(0-9_\-+={\[}\]:;"'<,>.?\//;
	return $w;
}
sub vowel_case { # V	lowercase vowels, uppercase consonants: "Crack96" -> "CRaCK96"
	my ($w) = @_;
	$w =~ tr/b-z/B-Z/;
	$w =~ tr/EIOU/eiou/;
	return $w;
}
sub keyboard_right { # R	shift each character right, by keyboard: "Crack96" -> "Vtsvl07"
	my ($w) = @_;
	# same behavior as john1.8.0.3-jumbo. I do not think all on the far right are 'quite' right, but at least it matches.
	# it's a very obsure rule, and not likely to have too many real world passwording implications.
	$w =~ tr/`~1qaz!QAZ2wsx@WSX3edc#EDC4rfv$RFV5tgb%TGB6yhn^YHN7ujm&UJM8ik,*IK<9ol.(OL>0p;)P:\-[_{=+\/?/1!2wsx@WSX3edc#EDC4rfv$RFV5tgb%TGB6yhn^YHN7ujm&UJM8ik,*IK<9ol.(OL>0p;\/)P:?\-['_{"=]+}\\|\\|/;
	return $w;
}
sub keyboard_left { # L	shift each character left, by keyboard: "Crack96" -> "Xeaxj85"
	my ($w) = @_;
	# idential output as john1.8.0.3-jumbo
	$w =~ tr/2wsx3edc4rfv5tgb6yhn7ujm8ik,9ol.0p;\/@WSX#EDC$RFV%TGB^YHN&UJM*IK<(OL>)P:?1!\-[_{=]+}'"/1qaz2wsx3edc4rfv5tgb6yhn7ujm8ik,9ol.!QAZ@WSX#EDC$RFV%TGB^YHN&UJM*IK<(OL>`~0p)P\-[_{;:/;
	return $w;
}
sub find_any_chars {
	# this function probably could be optimized, but as written, it works
	# well for all = / ? ( ) % type rejection rules.
	my ($w, $c) = @_;
	# some 'corrections' are needed to get a string to play nice in the reg-x we have
	$c =~ s/\\/\\\\/g; # change \ into \\
	$c =~ s/\^/\\\^/g; # change ^ into \^
	$c =~ s/\-/\\\-/g; # change - into \-
	$c =~ s/\]/\\\]/g; # change ] into \]

	$w =~ s/[^$c]*//g; # The main regex. will change w the characters that were seen in original $c value.
	return length($w);
}
sub check_rule_word {
	my ($word, $crk, $rule) = @_;
	$M = $word;  # memory
	$rejected = 0;
	$ruletrycnt{$rule} += 1;
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
		if ($c eq 'S') { $word = shift_case($word); next; }
		if ($c eq 'V') { $word = vowel_case($word); next; }
		if ($c eq 'R') { $word = keyboard_right($word); next; }
		if ($c eq 'L') { $word = keyboard_left($word); next; }
		if ($c eq '>') { my $n=get_num_val($rc[++$i],$word); if(length($word)<=$n){$rejected=1; return 0; } next; }
		if ($c eq '<') { my $n=get_num_val($rc[++$i],$word); if(length($word)>=$n){$rejected=1; return 0; } next; }
		if ($c eq '_') { my $n=get_num_val($rc[++$i],$word); if(length($word)!=$n){$rejected=1; return 0; } next; }
		if ($c eq '\''){ my $n=get_num_val($rc[++$i],$word); if(length($word)> $n){$word=substr($word,0,$n);} next; }
		#
		#   -c -8 -s -p -u -U ->N -<N -: (rejection)
		#   Not sure how to handle these, since we do not have a running john environment
		#   to probe to know what/how these impact us.
		#
		if ($c eq '-') {
			++$i;
			$c = $rc[$i];
			if ($c eq ':') {
				next;   # this one actually is done, lol.
			}
			# these are place holders now, until I can figure them out.
			if ($c eq 'c') { next; }
			if ($c eq '8') { next; }
			if ($c eq 's') { next; }
			if ($c eq 'p') { next; }
			if ($c eq 'u') { next; }
			if ($c eq 'U') { next; }
			if ($c eq '>') { ++$i; next; }
			if ($c eq '<') { ++$i; next; }
			debug(1, "unknown length rejection rule: -$c character $c not valid.\n");
			next;
		}
		if ($c eq 's') { #   sXY & s?CY
			my $chars = "";
			if ($rc[++$i] eq "?") { $chars = get_class($rc[++$i]); }
			else { $chars = $rc[$i]; }
			my $ch = $rc[++$i];
			$word=replace_chars($word, $ch, $chars);
			next;
		}
		if ($c eq 'D') { # DN
			my $pos = get_num_val($rc[++$i], $word);
			if ($pos >= 0 && $pos <= length($word)) {
				$word = substr($word, 0,$pos-1).substr($word, $pos,length($word));
			}
			next;
		}
		if ($c eq 'x') { # xNM
			my $pos = get_num_val($rc[++$i], $word);
			my $len = get_num_val($rc[++$i], $word);
			if ($pos >= 0 && $pos <= length($word)) {
				$M = substr($word, $pos,$len);
			}
			next;
		}
		if ($c eq 'i') { # iNX
			my $pos = get_num_val($rc[++$i], $word);
			if ($pos >= 0 && $pos <= length($word)) {
				substr($word, $pos,0) = $rc[++$i];
			}
			next;
		}
		if ($c eq 'M') { # M
			$M = $word;
			next;
		}
		if ($c eq 'Q') { # Q
			if ($M eq $word) {
				$rejected = 1;
				return 0;
			}
			next;
		}
		if ($c eq '!') { # !X  !?C  (rejection)
			my $chars;
			if ($rc[++$i] == '?') { $chars = get_class($rc[++$i]); }
			else { $chars = $rc[$i]; }
			if (find_any_chars($word, $chars)) {
				$rejected = 1;
				return 0;
			}
			next;
		}
		if ($c eq '/') { # /X  /?C  (rejection)
			my $chars;
			if ($rc[++$i] == '?') { $chars = get_class($rc[++$i]); }
			else { $chars = $rc[$i]; }
			if (!find_any_chars($word, $chars)) {
				$rejected = 1;
				return 0;
			}
			next;
		}
		if ($c eq '=') { # =NX  =N?C  (rejection)
			my $chars;
			my $pos = get_num_val($rc[++$i], $word);
			if ($pos >= 0 && $pos <= length($word)) {
				my $w = substr($word, $pos, 1);
				if ($rc[++$i] == '?') { $chars = get_class($rc[++$i]); }
				else { $chars = $rc[$i]; }
				if (!find_any_chars($w, $chars)) {
					$rejected = 1;
					return 0;
				}
			}
			next;
		}
		if ($c eq '(') { # (X  (?C  (rejection)
			my $chars;
			if (length($word)==0) { $rejected = 1; return 0; }
			if ($rc[++$i] == '?') { $chars = get_class($rc[++$i]); }
			else { $chars = $rc[$i]; }
			if (!find_any_chars(substr($word,0,1), $chars)) {
				$rejected = 1;
				return 0;
			}
			next;
		}
		if ($c eq ')') { # )X  )?C  (rejection)
			my $chars;
			if (length($word)==0) { $rejected = 1; return 0; }
			if ($rc[++$i] == '?') { $chars = get_class($rc[++$i]); }
			else { $chars = $rc[$i]; }
			if (!find_any_chars(substr($word,length($word)-1,1), $chars)) {
				$rejected = 1;
				return 0;
			}
			next;
		}
		if ($c eq '%') { # %NX  %N?C  (rejection)
			my $chars;
			my $n = get_num_val($rc[++$i]);
			if ($rc[++$i] == '?') { $chars = get_class($rc[++$i]); }
			else { $chars = $rc[$i]; }
			if (find_any_chars(substr($word,length($word)-1,1), $chars) < $n) {
				$rejected = 1;
				return 0;
			}
			next;
		}
		if ($c eq 'X') { # XNMI
			my $posM = get_num_val($rc[++$i], $M);  # note using $M not $word.
			my $len = get_num_val($rc[++$i], $M);
			my $posI = get_num_val($rc[++$i], $word);
			if ($posM >= 0 && $len > 0 && $posI >= 0) {
				substr($word, $posI, 0) = substr($M, $posM, $len);
			}
		}
		if ($c eq 'o') { # oNX
			my $pos = get_num_val($rc[++$i], $word);
			if ($pos >= 0 && $pos <= length($word)) {
				substr($word, $pos,1) = $rc[++$i];
			}
		}
		if ($c eq 'T') { # TN  (toggle case of letter at N)
			my $pos = get_num_val($rc[++$i], $word);
			if ($pos >= 0) {
				my $c = substr($word, $pos, 1);
				if (ord($c) >= ord('a') && ord($c) <= ord('z')) { $c .= uc $c; }
				elsif (ord($c) >= ord('A') && ord($c) <= ord('Z')) { $w .= lc $c; }
				substr($word, $pos, 1) = $c;
			}
			$word = rotr($word); next; }
		if ($c eq '@') {  # @X & @?C
			my $chars = "";
			if ($rc[++$i] eq "?") { $chars = get_class($rc[++$i]); }
			else { $chars = $rc[$i]; }
			$word=purge($word, $chars);
			next;
		}
		if ($c eq 'A') { # AN"STR"  with de-ESC in STR
			my $pos = get_num_val($rc[++$i], $word);
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
		debug(1, "Do not know how to handle character $c in the rule\n");
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
sub get_class {
	my ($c) = @_;
	if ($c eq '?') { debug(2,"Doing get class of ?\n"); return $cclass{'?'}; }
	return $cclass{$c};
}
sub get_num_val {
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
	elsif ($p eq '*') { return 110; }
	elsif ($p eq '-') { return 109; }
	elsif ($p eq '+') { return 111; }
#	elsif ($p eq 'a...k') {}
	elsif ($p eq 'z') {$p = length($w); }
	if ($p > length($w)) { return -1; }
	if ($p eq 'l') { my $m = length($M); return $m; }
	if ($p eq 'm') { my $m = length($M); if ($m>0){$m-=1;} return $m; }
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
		} else {
			if ($rejected) {
				$rulerejcnt{$rule} += 1;
			}
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
		if ($ch[$i+1] ne '-' || ($ch[$i] eq '\\' && $ch[$i+1] eq '-')) {
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
		debug(4, "doing range fix for $ch[$i]$ch[i+1]$ch[$i+2]\n");
		for (my $c = ord($ch[$i]); $c <= ord($ch[$i+2]); ++$c) {
			$chars .= chr($c);
		}
		$i += 2;
	}
	return $chars;
}
sub handle_backref {
	my ($which_group, $idx, $c, $pos, $s) = @_;
	# find any /p[ or /p0[] before the first [ and replace with the $idx from it's group
	# find any /0 before the first [  and replace with $c
	# find any /p$idx[] and replace with the $idx from it's group
	# find any /$idx and replace with $c
	return $s;
}
# pre-processor: handles [] \xHH and \# and \p# backreferences. NOTE, recursive!
sub check_rules {
	my ($orig, $inp, $crk, $rules, $which_group) = @_;
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
	my $idx = 0;
	$which_group += 1;
	foreach my $c (@chars) {
		$idx++;
		my $s = handle_backref($which_group, $idx, $c, $pos2, $rules);
		if ($s ne $rules) {debug(4, "before handle_backref($which_group, $idx, $rules)\handle_backref returned $s\n"); }
		debug(4, "before sub=$s\n");
		substr($s, $pos, $pos2-$pos+1) = $c;
		debug(4, "after sub=$s\n");
		if (check_rules(0, $inp, $crk, $s, $which_group)) { return 1; }
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
	$cclass{'?'}='?';
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
