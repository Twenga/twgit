#!/usr/bin/env bash

##
# twgit
#
#
#
# Copyright (c) 2011 Twenga SA
# Copyright (c) 2012-2013 Geoffroy Aubry <geoffroy.aubry@free.fr>
# Copyright (c) 2012 Laurent Toussaint <lt.laurent.toussaint@gmail.com>
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
# @copyright 2011 Twenga SA
# @copyright 2012-2013 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @copyright 2012 Laurent Toussaint <lt.laurent.toussaint@gmail.com>
# @license http://www.apache.org/licenses/LICENSE-2.0
#



#--------------------------------------------------------------------
# Mac OS X compatibility layer
#--------------------------------------------------------------------

##
# Display the last update time of specified path, in seconds since 1970-01-01 00:00:00 UTC.
# Compatible Linux and Mac OS X.
#
# @param string $1 path
#
function getLastUpdateTimestamp () {
    local path="$1"
    result=$(stat -f "%m" "$path" 2> /dev/null)
    if [ ! -z "${result}" ] ; then
        echo ${result}
    else
        date -r "$path" +%s
    fi
}

##
# Display the specified timestamp converted to date with "+%Y-%m-%d %T" format.
# Compatible Linux and Mac OS X.
#
# @param int $1 timestamp
#
function getDateFromTimestamp () {
    local timestamp="$1"
    result=$(date -r "$timestamp" "+%Y-%m-%d %T" 2> /dev/null)
    if [ ! -z "${result}" ] ; then
        echo ${result}
    else
        date --date "1970-01-01 $timestamp sec" "+%Y-%m-%d %T"
    fi
}

##
# Execute sed with the specified regexp-extended pattern.
# Compatible Linux and Mac OS X.
#
# @param string $1 pattern using extended regular expressions
#
function sedRegexpExtended () {
    local pattern="$1"
    result=$(sed -E "$pattern")
    if [ ! -z "${result}" ]; then
        echo ${result};
    else
        sed -r "$pattern";
    fi
}