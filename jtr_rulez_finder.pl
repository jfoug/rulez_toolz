#!/usr/bin/perl -w
use String::Scanf;
use strict;
use jtr_rulez;

my $dbg=0;                      # used for debugging. NORMALLY keep this at 0 -D# on command line can also set it.
if (@ARGV && substr($ARGV[0], 0, 2) eq "-D") { $dbg = substr($ARGV[0], 2, 1); print}
my %rulecnt=();                 # Rule and counts accumulated here.
my %rulerejcnt=();              # number of words rejected for this rule.
my %ruletrycnt=();              # number of words tested by this rule.
my %stats=();
my $M;                          # memorized word.
my $rejected;

$stats{check_rules} = 0; $stats{check_rule} = 0; $stats{rule_word} = 0;
$rulerejcnt{unk} = $rulecnt{unk} = $ruletrycnt{unk} = 0;

my @DIC = ("abcde0123bcccx897"); #, "pass", "passwrod", "fdsj", "tortyor442", "fdkjla84fjaf", "JIELF", "big ont", "938912374", "563562", "5675lll9575", "aaaaaaaaa" );

foreach my $s (<STDIN>) {
	chomp $s;
	my $found = 0;
	my $idx = 0;
	$ruletrycnt{unk} += 1;
	my $crypt_word = $s;
	foreach my $inp_word (@DIC) {
	next if ($found > 0);

	next if (($found = check_rules($idx, $inp_word, $crypt_word, '$[abc] $[defg] $\p[1234567]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] $\0 (?\p[za] \p1[lc] ^\1 $! <- Az"!!"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '>4')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '>4lQ')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?d >4 Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '>4')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?d >4 Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?D >4 Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '>4 [lcCutdrf{}] Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?d >4 M [lcCutdrf{}] Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?D >4 M [lcCutdrf{}] Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?d >3 Az"12" Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?d >3 Az"123" Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?d >3 $[0-9] Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?d >3 M [lc] Q $[0-9]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?d >3 $[a-z]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?d >3 ^[0-9] Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?d >3 ^[a-z]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?d >3 $[0-9]$[0-9] Q')) != 0);

	# the entire ruleset from jumbo john.conf file.
	next if (($found = check_rules($idx, $inp_word, $crypt_word, ':')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-s x**')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c (?a c Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c l Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-s-c x** /?u l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-<6 >6 \'6')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-<7 >7 \'7 l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-<6 -c >6 \'6 /?u l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-<5 >5 \'5')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?d @?d >4')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?d @?d M @?A Q >4')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?d @?d >4 M [lc] Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?d @?d M @?A Q >4 M [lc] Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '@?D Q >4')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?d @?d >3 <* $[0-9] Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?d @?d M >3 <* [lc] Q $[0-9] Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?d @?d >3 <- Az"12" Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?d @?d M >3 <- [lc] Q Az"12"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?d @?d >3 Az"123" Q <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?d @?d M >3 [lc] Q Az"123" <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?d @?d >2 d Q <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?d @?d >2 M [lc] Q d<+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '(?a )?d /?d \'p Xpz0')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, ')?a (?d /?a \'p Xpz0')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '<* d')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, 'r c')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c <* (?a d c')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-<5 -c >5 \'5 /?u l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c u Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c )?a r l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] <* !?A \p1[lc] p')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c <* c Q d')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-<7 -c >7 \'7 /?u')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-<4 >4 \'4 l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c <+ (?l c r')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c <+ )?l l Tm')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-<3 >3 \'3')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-<4 -c >4 \'4 /?u')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-<3 -c >3 \'3 /?u l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c u Q r')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '<* d M \'l f Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c <* l Q d M \'l f Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '>[2-8] x1\1')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '>9 \[')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '>[3-9] x2\p[2-8]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '>[4-9] x3\p[2-7]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c >[2-8] x1\1 /?u l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c >9 \[ /?u l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c >[3-9] x2\p[2-8] /?u l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c >[4-9] x3\p[2-7] /?u l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '<* l $[1-9!0a-rt-z"-/:-@\[-`{-~]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c <* (?a c $[1-9!0a-rt-z"-/:-@\[-`{-~]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] <* !?A (?\p1[za] \p1[lc] $s M \'l p Q X0z0 \'l $s')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] <* /?A (?\p1[za] \p1[lc] $s')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '<* l r $[1-9!]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c <* /?a u $[1-9!]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] <- (?\p1[za] \p1[lc] Az"\'s"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] <- (?\p1[za] \p1[lc] Az"!!"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] (?\p1[za] \p1[lc] $! <- Az"!!"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] /?v @?v >2 (?\p1[za] \p1[lc]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?v @?v >2 <* d')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '<* l [PI]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c <* l [PI] (?a c')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] <* (?\p1[za] \p1[lc] )y omi $e')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] <* (?\p1[za] \p1[lc] )e \] )i val1 oay')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /[aelos] s\0\p[4310$] (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /a /[elos] sa4 s\0\p[310$] (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /e /[los] se3 s\0\p[10$] (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /l /[os] sl1 s\0\p[0$] (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /o /s so0 ss$ (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /a /e /[los] sa4 se3 s\0\p[10$] (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /a /l /[os] sa4 sl1 s\0\p[0$] (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /a /o /s sa4 so0 ss$ (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /e /l /[os] se3 sl1 s\0\p[0$] (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /[el] /o /s s\0\p[31] so0 ss$ (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /a /e /l /[os] sa4 se3 sl1 s\0\p[0$] (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /a /[el] /o /s sa4 s\0\p[31] so0 ss$ (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /e /l /o /s se3 sl1 so0 ss$ (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] l /a /e /l /o /s sa4 se3 sl1 so0 ss$ (?\p1[za] \p1[:c]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, 'l ^[1a-z2-90]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c l Q ^[A-Z]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '^[A-Z]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, 'l ^["-/:-@\[-`{-~]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] <9 (?a \p1[lc] A0"[tT]he"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] <9 (?a \p1[lc] A0"[aA]my"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] <9 (?a \p1[lc] A0"[mdMD]r"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] <9 (?a \p1[lc] A0"[mdMD]r."')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] <9 (?a \p1[lc] A0"__"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '<- !?A l p ^[240-9]')) != 0);

# single crap ;)
#	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-p-c (?a 2 (?a c 1 [cl]')) != 0);
#	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-p 1 <- $[ _\-] + l')) != 0);
#	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-p-c 1 <- (?a c $[ _\-] 2 l')) != 0);
#	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-p-c 1 <- l $[ _\-] 2 (?a c')) != 0);
#	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-p-c 1 <- (?a c $[ _\-] 2 (?a c')) != 0);
#	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-p-[c:] 1 \p1[ur] 2 l')) != 0);
#	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-p-c 2 (?a c 1 [ur]')) != 0);
#	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-p-[c:] 1 l 2 \p1[ur]')) != 0);
#	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-p-c 1 (?a c 2 [ur]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] (?a \p1[lc] [{}]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] (?a \p1[lc] [{}] \0')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c <+ )?u l Tm')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c T0 Q M c Q l Q u Q C Q X0z0 \'l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c T[1-9A-E] Q M l Tm Q C Q u Q l Q c Q X0z0 \'l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c l Q T[1-9A-E] Q M T\0 Q l Tm Q C Q u Q X0z0 \'l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c >2 <G %2?a [lu] T0 M T2 T4 T6 T8 TA TC TE Q M l Tm Q X0z0 \'l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c >2 /?l /?u t Q M c Q C Q l Tm Q X0z0 \'l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '>[2-8] D\p[1-7]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '>[8-9A-E] D\1')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c /?u >[2-8] D\p[1-7] l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c /?u >[8-9A-E] D\1 l')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '=1?a \[ M c Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c (?a >[1-9A-E] D\1 c')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] >3 (?a \p1[lc] i[12].')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '<- l Az"[190][0-9]"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c <- (?a c Az"[190][0-9]"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '<- l Az"[782][0-9]"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c <- (?a c Az"[782][0-9]"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '<* l $[A-Z]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c <* (?a c $[A-Z]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c u /I sIi')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '%2?a C Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '/?A S Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c /?v V Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, ':[RL] Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, 'l Q [RL]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c (?a c Q [RL]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, ':[RL] \0 Q')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '<- l ^[1!@#$%^&*\-=_+.?|:\'"] $\1')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '<- l ^[({[<] $\p[)}\]>]')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '<- l Az"[63-5][0-9]"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-c <- (?a c Az"[63-5][0-9]"')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] (?a \p1[lc] Az"007" <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] (?a \p1[lc] Az"123" <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] (?a \p1[lc] Az"[0-9]\0\0" <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] (?a \p1[lc] Az"1234" <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] (?a \p1[lc] Az"[0-9]\0\0\0" <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] (?a \p1[lc] Az"12345" <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] (?a \p1[lc] Az"[0-9]\0\0\0\0" <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] (?a \p1[lc] Az"123456" <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, '-[:c] (?a \p1[lc] Az"[0-9]\0\0\0\0\0" <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, 'l Az"19[7-96-0]" <+ >-')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, 'l Az"20[01]" <+ >-')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, 'l Az"19[7-9][0-9]" <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, 'l Az"20[01][0-9]" <+')) != 0);
	next if (($found = check_rules($idx, $inp_word, $crypt_word, 'l Az"19[6-0][9-0]" <+')) != 0);
	++$idx;
	}
	if ($found == 0) {
		$rulecnt{unk} += 1;
		debug(0, "No rule found:  $s\n");
	}
}

sub debug {
	my ($v, $m) = @_;
	if ($dbg < $v) { return; }
	print $m;
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

sub check_rules {  my ($idx, $inp, $crk, $rules) = @_;
	my $cnt=50000; my $rej; my $ret = 0;
	#debug(1, "check_rules:  $idx, $inp, $crk, $rules\n");
	my $rule = jtr_rule_pp_init($rules, 125, $cnt);
	$rej = jtr_rule_rejected();
	if ($idx == 0) {
		#debug(0, "check_rules:  $idx, $inp, $crk, $rules\n");
		$stats{check_rules} += 1;
		if (!defined $rulerejcnt{$rules}) { $rulerejcnt{$rules} = 0; }
		if (!defined $rulecnt{$rules})    { $rulecnt{$rules} = 0;    }
		if (!defined $ruletrycnt{$rules}) { $ruletrycnt{$rules} = 0; }
	}
	$cnt = 0;
	while ($ret == 0 && defined ($rule) && length($rule)>0) {
		$cnt++;
		#print " $rule\n";
		if ($rej != 0) {
			$rulerejcnt{$rules} += 1;
		} else {
			#print "  calling jtr_run_rule($rule,$inp)\n";
			my $val = jtr_run_rule($rule, $inp);
			$rej = jtr_rule_rejected();
			#print "  $inp=$val\n";
			if ($val eq $crk) {
				#print "$inp cracked by rule $rules\n";
				$rulecnt{$rules} += 1;
				#print "word=$inp  crk=$crk rule = $rules  val after rule=$val\n";
				$ret = 1;
				next;
			}
		}
		$rule = jtr_rule_pp_next();
		$rej = jtr_rule_rejected();
	}
	$stats{rule_word} += $cnt;
	$ruletrycnt{$rules} += $cnt;
	if ($idx == 0) { $stats{check_rule} += $cnt; }
	return $ret;
}
