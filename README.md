# rulez_toolz
Rule and word tools for JtR.

single_rules_finder.pl  This script takes a john.pot and back finds which single rules found each word, listing accumulations
    To use this tool, crack some words using -single mode. Then make sure all the rules you were using are in the perl script
    then use john to show the cracks:    ./john -show -pot=cracked_with_single.pot > input
    then run the script with   ./single_rules_finder.pl < input

