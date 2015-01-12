#!/usr/bin/env bash

##
# Usage: tests/inc/codeCoverage.sh <src-file> <tests-file>
#     where <src-file> is a file containing all Bash source filenames to analyze,
#     and <tests-file> is a file containing all PHP unit tests filenames.
#
# Example: tests/inc/codeCoverage.sh \
#     <(find $(pwd)/inc -type f -name '*.sh' && echo $(pwd)/twgit) \
#     <(find $(pwd) -type f -name '*Test.php')
#
#
#
# Copyright (c) 2012-2015 Geoffroy Aubry <geoffroy.aubry@free.fr>
# Copyright (c) 2012-2014 Laurent Toussaint <lt.laurent.toussaint@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
# for the specific language governing permissions and limitations under the License.
#
# @copyright 2012-2015 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @copyright 2012-2014 Laurent Toussaint <lt.laurent.toussaint@gmail.com>
# @license http://www.apache.org/licenses/LICENSE-2.0
#



set -o nounset
set -o pipefail

. ./inc/compatibility.inc.sh

src_file="$1"
test_file="$2"
rStats="/tmp/file.$$.$RANDOM"
rCovers="/tmp/file.$$.$RANDOM"

# Compute stats about Bash functions in a CSV file plus an extra line for total lines of code.
# CSV format: path:function_name:start_line:end_line:nb_of_line_of_code
# Use % instead of \000 in tr command, octal value doesn't work with sed command in mac os x
# Skip functions with '# @codeCoverageIgnore'.
cat "$src_file" \
    | sort \
    | xargs grep -E '^\s*#+\s*@codeCoverageIgnore\s*$|^\s*function\s+([a-z0-9_-]+)\b|^\}\s*$' \
        --ignore-case --only-matching --line-number -r --with-filename \
    | sedRegexpExtended 's#^./##' \
    | awk -F: '
        BEGIN {ignore=0; fct_begin=-1; fct_end=-1; fct_length=0}
        {
            if ($3 ~ /^\s*function/) {
                fct_name=substr($3, 10); fct_begin=$2; fct_end=fct_begin; fct_length=0
            } else if ($3 ~ /^}\s*$/) {
                if (ignore == 0) {
                    fct_end=$2
                    fct_length=fct_end-fct_begin-1
                    print $1"\t"fct_name"\t"fct_begin"\t"fct_end"\t"fct_length
                } else {
                    ignore=0
                }
            } else if ($3 ~ /@codeCoverageIgnore/) {
                ignore=1
            }
        }' \
    | sort \
    > $rStats

# Find all @shcovers annotations in test code and store them in a file.
# Format of annotation: @shcover path::function
# Example: @shcovers inc/common.inc.sh::assert_git_configured
cat "$test_file" \
    | sort \
    | xargs grep -E '^\s*\*\s*@shcovers\s+.+::.' --ignore-case -r --no-filename \
    | tr -d '\r' \
    | sedRegexpExtended 's/^.*@shcovers[ ]*//' \
    | sedRegexpExtended 's/::/\t/' \
    | sort | uniq \
    > $rCovers

# Compute coverage:
iTotal="$(awk -F'\t' 'BEGIN {sum=0} {sum+=$5} END {print sum}' $rStats)"
iSum="$(grep -f $rCovers $rStats | awk -F'\t' 'BEGIN {sum=0} {sum+=$5} END {print sum}')"
(( p=iSum*1000/iTotal ))
fPercent="${p:0:$((${#p}-1))}.${p:$((${#p}-1))}"

# Example: "Estimated Bash code coverage: .4% (6 of 1334 lines)."
echo -e "\n\033[1;33mEstimated Bash code coverage: \033[1;37m$fPercent%\033[0;33m ($iSum of $iTotal lines)."

# Bash covered functions:
echo -e "\n\033[1;32mBash covered functions:\033[0m"
( echo -e 'Script\tFunction\tStart line\tEnd line\tLOC'; grep -f $rCovers $rStats ) \
    | column -t -s $'\t' \
    | awk '{if (NR == 1) print "\033[1;37m" $0 "\033[0m"; else print $0}' \
    | sedRegexpExtended 's/^/    /'

# Bash uncovered functions:
echo -e "\n\033[1;31mBash uncovered functions:\033[0m"
if grep -f $rCovers -v $rStats -q; then
    ( echo -e 'Script\tFunction\tStart line\tEnd line\tLOC'; grep -f $rCovers -v $rStats ) \
        | column -t -s $'\t' \
        | awk '{if (NR == 1) print "\033[1;37m" $0 "\033[0m"; else print $0}' \
        | sedRegexpExtended 's/^/    /'
else
    echo '    All functions are covered.'
fi

# Example: "Estimated Bash code coverage: .4% (6 of 1334 lines)."
echo -e "\n\033[1;33mEstimated Bash code coverage: \033[1;37m$fPercent%\033[0;33m ($iSum of $iTotal lines)."

rm -f "$rStats"
rm -f "$rCovers"
