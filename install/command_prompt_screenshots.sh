#!/bin/bash

##
# Generate screenshots of help on command prompt.
#
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/
# or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
#
# @copyright 2012 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @license http://creativecommons.org/licenses/by-nc-sa/3.0/
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
twgit hotfix
twgit release
twgit tag"
IFS="$(echo -e "\n\r")"
for cmd in $cmds; do
    take_snapshot "$cmd" || exit $?
done
