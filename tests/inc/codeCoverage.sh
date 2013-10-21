#!/bin/bash

##
# Usage: /bin/bash tests/inc/codeCoverage.sh
# @copyright 2012-2013 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @copyright 2012 Laurent Toussaint <lt.laurent.toussaint@gmail.com>
# @license http://www.apache.org/licenses/LICENSE-2.0
#

. ./inc/os_compatibility.inc.sh


rStats="/tmp/file.$$.$RANDOM"
rCovers="/tmp/file.$$.$RANDOM"

# Compute stats about Bash functions in a CSV file plus an extra line for total lines of code.
# CSV format: path:function_name:start_line:end_line:nb_of_line_of_code
# Use % instead of \000 in tr command, octal value doesn't work with sed command in mac os x
grep -E '^\s*function\s+([a-z0-9_-]+)\b|^\s*\}\s*$' --ignore-case --only-matching --line-number -r --include=twgit --include=*.sh --with-filename . \
    | sedRegexpExtended 's#^./##' \
    | tr '\n' '%' \
    | sedRegexpExtended 's/:([0-9]+):function[ ]+([a-zA-Z0-9_-]+)%[^:]+:([0-9]+):\}%/:\2:\1:\3\'$'\n/g' \
    | grep -vE '^install/' \
    | grep -vE '^tests/' \
    | sort \
    | awk -F: 'BEGIN {sum=0} {diff=$4-$3; sum += diff; print $0":"diff} END {print sum}' \
    > $rStats

# Find all @shcovers annotations in test code and store them in a file.
# Format of annotation: @shcover path::function
# Example: @shcovers inc/common.inc.sh::assert_git_configured
grep -E '^\s*\*\s*@shcovers\s+.+::.' --ignore-case -r --no-filename --include=*Test.php --exclude-dir=tests/lib ./tests \
    | tr -d '\r' \
    | sed 's/^.*@shcovers[ ]*//' \
    | sed 's/::/:/' \
    | sort | uniq \
    > $rCovers

iSum="$(grep -f $rCovers $rStats | awk -F: 'BEGIN {sum=0} {sum+=$5} END {print sum}')"
iTotal="$(tail -n 1 $rStats)"
sPhpCmd="echo round($iSum*100/$iTotal, 1);"
fPercent="$(php -r "$sPhpCmd")"

# Example: (i) Estimated Bash code coverage: .4% (6 of 1334 lines).
echo -e "\n\033[1;33m(i) Estimated Bash code coverage: $fPercent% ($iSum of $iTotal lines)."
