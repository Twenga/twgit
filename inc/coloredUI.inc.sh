#!/usr/bin/env bash

##
# Provide an easy way to display colored and decorated messages in Bash: title, question, error, warning, success...
# Just include this script, define colors, bold colors and headers, then call CUI_displayMsg() method.
#
# Generic example:
#     CUI_displayMsg type 'Message with <b>bold section</b>.'
#      `==> '<type.header><type>message with <type.bold>bold section<type>.\033[0m'
#
# Concrete example:
#	  . coloredUI.inc.sh
#     CUI_COLORS=(
#	      [error]='\033[1;31m'
#	      [help]='\033[0;36m'
#	      [help.bold]='\033[1;36m'
#	      [help.header]='\033[1;36m(i) '
#     )
#     CUI_displayMsg error 'Invalid number!'
#	   `==> '\033[1;31mInvalid number!\033[0m'
#     CUI_displayMsg help 'This is a <b>valuable</b> information.'
#	   `==> '\033[1;36m(i) \033[0;36mThis is a \033[1;36mvaluable\033[0;36m information.\033[0m'
#
# Requirements:
#   - Bash v4 (2009) and above
#
# Color codes :
#   - http://www.tux-planet.fr/les-codes-de-couleurs-en-bash/
#   - http://confignewton.com/wp-content/uploads/2011/07/bash_color_codes.png
#
#
#
# Copyright (c) 2012-2013 Geoffroy Aubry <gaubry@hi-media.com>
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
# @copyright 2012-2013 Geoffroy Aubry <gaubry@hi-media.com>
# @license http://www.apache.org/licenses/LICENSE-2.0
#



##
# Colors and decorations types.
#
# For each type, message will be displayed as follows (.header and .bold are optional):
#     '<type.header><type>message with <type.bold>bold section<type>.\033[0m'
#
# For example:
#     CUI_COLORS=(
#         [type]='\033[1;31m'
#         [type.bold]='\033[1;33m'
#         [type.header]='\033[1m\033[4;33m/!\\\033[0;37m '
#     )
#
# @var associative array
#
declare -A CUI_COLORS

##
# Check if the specified key exists in $CUI_COLORS associative array.
#
# @param string $1 key to check
# @return int 0 if key exists, else 1
# @testedby TwgitCUITest
#
function CUI_isSet () {
    local key="$1"
    [ -z "${CUI_COLORS[$key]-}" ] && return 1 || return 0
}

##
# Display a message of the specified type, using ${CUI_COLORS[$type]}.
# If ${CUI_COLORS[$type.header]} exists, then this will be used as prefix.
# If ${CUI_COLORS[$type.bold]} exists, then this will be used to display text in '<b>...</b>' tags.
# In any case <b> tags will be stripped.
#
# @param string $1 type of the message (error, title, ...)
# @param string $2..$n message
# @see $CUI_COLORS
# @testedby TwgitCUITest
#
function CUI_displayMsg () {
    local type=$1; shift
    local msg="$*"
    local bold_pattern_start bold_pattern_end header

    # Color:
    if ! CUI_isSet "$type"; then
        echo "Unknown display type '$type'!" >&2
        echo -n 'Available types: ' >&2
        local types=$(echo "${!CUI_COLORS[*]}" | tr ' ' "\n" | grep -vE "\.bold$" | grep -vE "\.header$" | sort)
        local trimmed_types=$(echo $types)
        echo "${trimmed_types// /, }." >&2
        exit 1
    fi

    # Header:
    if ! CUI_isSet "$type.header"; then
        header=''
    else
        header="${CUI_COLORS[$type'.header']}"
    fi

    # Bold pattern:
    if ! CUI_isSet "$type.bold"; then
        bold_pattern_start=''
        bold_pattern_end=''
    else
        bold_pattern_start="${CUI_COLORS[$type'.bold']}"
        bold_pattern_end="${CUI_COLORS[$type]}"
    fi

    # Display:
    msg="${msg//<b>/$bold_pattern_start}"
    msg="${msg//<\/b>/$bold_pattern_end}"
    echo -e "$header${CUI_COLORS[$type]}$msg\033[0m"
}
