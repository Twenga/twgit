#!/bin/bash

##
# Generate screenshots of help on command prompt.
#
# Usage: bash command_prompt_screenshots.sh <twgit_root_dir>
#
#
#
# Copyright (c) 2012 Geoffroy Aubry <geoffroy.aubry@free.fr>
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
# @copyright 2012 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @license http://www.apache.org/licenses/LICENSE-2.0
#



root_dir="$1"
tmp_dir='/tmp'
doc_dir="$root_dir/doc"
sleep_time=3
gnome_terminal_title="twgit"

function take_snapshot () {
    local twgit_cmd="$@"
    local screenshot_filename="screenshot-${twgit_cmd// /-}"
    local error_code

    gnome-terminal --disable-factory --full-screen --profile=twgit -e "bash -c \"echo -e '\\033[01;33m$ \033[0m$twgit_cmd'; bash $root_dir/$twgit_cmd; echo -en '\\033[01;33m$ '; sleep $((sleep_time + 3))\"" & PID=$!
    sleep $sleep_time
    local WID=$(xwininfo -root -tree | grep "\"$gnome_terminal_title\":" | awk '{ print $1 }')
    #local TIMESTAMP="$(date +%Y%m%d%H%M%S)"
    xwd -nobdrs -out $tmp_dir/$screenshot_filename.xwd -id $WID && \
    convert -chop x22 -trim -border 2x2 -bordercolor "#000000" "$tmp_dir/$screenshot_filename.xwd" "$doc_dir/$screenshot_filename.png" && \
    rm -f "$tmp_dir/$screenshot_filename.xwd"
    error_code=$?
    kill -9 $PID
    return $error_code
}

cmds="twgit
twgit feature
twgit demo
twgit hotfix
twgit release
twgit tag"
IFS="$(echo -e "\n\r")"
for cmd in $cmds; do
    take_snapshot "$cmd" || exit $?
done
