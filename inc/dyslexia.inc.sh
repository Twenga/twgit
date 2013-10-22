#!/bin/bash

##
# dyslexia
#
# Copyright (c) 2013 Sebastien Hanicotte <shanicotte@hi-media.com>
#
# Provide an easy way to detect words in disorder.
# Just include this script, define new words scheme, then call guess_dyslexia method.
# This script is using the colored_ui to display Warning message
#

declare -A dyslexia
dyslexia['1a2e1f1r1t1u']='feature'
dyslexia['1d1e1m1o']='demo'
dyslexia['1a3e1l1r1s']='release'
dyslexia['1f1h1i1o1t1x']='hotfix'
dyslexia['1a1g1t']='tag'
dyslexia['1a1c1e1l1n']='clean'
dyslexia['2i1n1t']='init'
dyslexia['1a1d1e1p1t1u']='update'
dyslexia['1d1e1l1p']='help'

dyslexia['1a1r1s2t']='start'
dyslexia['1f1h2i1n1s']='finish'
dyslexia['1a2s2t1u']='status'
dyslexia['1c1e1i2m1o1r1s2t']='commiters'
dyslexia['2-1a5e1g1i1l1m1n1o2r1s1t']='merge-into-release'
dyslexia['1a1e1g1i1m1r1t']='migrate'
dyslexia['1h1p1s1u']='push'
dyslexia['2e1m1o1r1v']='remove'
dyslexia['1-2a1c1d1e1g2h1n1t1w']='what-changed'
dyslexia['1i1l1s1t']='list'
dyslexia['1-1a4e1f1g1m2r1t1u']='merge-feature'
dyslexia['2e1r1s1t']='reset'

##
# This add-on allows twgit to understand dyslexia
# This can be usefull when user has some keyboard disorder.
# @param string $1 action
#
function guess_dyslexia () {
    local word="$1"

    explodeWord="$(echo $word | fold -w1 | sort | uniq -c | tr -d '[:space:]\n')"

    resolve_dyslexia="$(echo ${dyslexia["$explodeWord"]})"

    if [[ -z "$resolve_dyslexia" ]];
    then
        RETVAL="$word";
    else
        if [[ "$word" != "$resolve_dyslexia" ]];
        then
            CUI_displayMsg warning "Assume '<b>$word</b>' was '<b>$resolve_dyslexia</b>'…"
        fi
        RETVAL="$resolve_dyslexia"
    fi
}
