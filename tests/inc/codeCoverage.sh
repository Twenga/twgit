#!/bin/bash

##
# @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
#



rStats="$(tempfile)"
rCovers="$(tempfile)"

# Compute stats about Bash functions in a CSV file plus an extra line for total lines of code.
# CSV format: path:function_name:start_line:end_line:nb_of_line_of_code
grep -E '^\s*function\s+([a-z0-9_-]+)\b|^\s*\}\s*$' --ignore-case --only-matching --line-number -r --include=twgit --include=*.sh --with-filename . \
    | sed -r 's#^./##' \
    | tr '\n' '\000' \
    | sed -r "s/:([0-9]+):function\s+([a-z0-9_-]+)\x00[^:]+:([0-9]+):\}\x00/:\2:\1:\3\n/ig" \
    | awk -F: 'BEGIN {sum=0} {diff=$4-$3; sum += diff; print $0":"diff} END {print sum}' \
    > $rStats

# Find all @shcovers annotations in test code and store them in a file.
# Format of annotation: @shcover path::function
# Example: @shcovers inc/common.inc.sh::assert_git_configured
grep -E '^\s*\*\s*@shcovers\s+.+::.' --ignore-case -r --no-filename --include=*Test.php --exclude-dir=tests/lib ./tests \
    | tr -d '\r' \
    | sed 's/^.*@shcovers\s*//i' \
    | sed 's/::/:/' \
    > $rCovers

iSum="$(grep -f $rCovers $rStats | awk -F: 'BEGIN {sum=0} {sum+=$5} END {print sum}')"
iTotal="$(tail -n 1 $rStats)"
sPhpCmd="echo round($iSum*100/$iTotal, 1);"
fPercent="$(php -r "$sPhpCmd")"

# Example: (i) Estimated Bash code coverage: .4% (6 of 1334 lines).
echo -e "\n\033[1;33m(i) Estimated Bash code coverage: $fPercent% ($iSum of $iTotal lines)."
