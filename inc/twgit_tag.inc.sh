#!/bin/bash

##
# twgit
#
# Copyright (c) 2011 Twenga SA.
#
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/
# or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
#
# @copyright 2011 Twenga SA
# @copyright 2012 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @license http://creativecommons.org/licenses/by-nc-sa/3.0/
#

assert_git_repository

##
# Affiche l'aide de la commande tag.
#
# @testedby TwgitHelpTest
#
function usage () {
    echo; help 'Usage:'
    help_detail '<b>twgit tag <action></b>'
    echo; help 'Available actions are:'
    help_detail '<b>list [-F]</b>'
    help_detail '    List 5 last tags. Add <b>-F</b> to do not make fetch.'; echo
    help_detail '<b>[help]</b>'
    help_detail '    Display this help.'; echo
}

##
# Action déclenchant l'affichage de l'aide.
#
# @testedby TwgitHelpTest
#
function cmd_help () {
    usage;
}

##
# Liste les tags.
# Gère l'option '-F' permettant d'éviter le fetch.
#
function cmd_list () {
    process_options "$@"
    process_fetch 'F'

    local max='5'
    local tags=$(get_all_tags $max)
    help "List $max last tags:"
    if [ -z "$tags" ]; then
        info 'No tag exists.'; echo
    else
        for tag in $tags; do
            info "Tag: $tag"
            git show tags/$tag --pretty=medium | head -n 4 | tail -n +2
        done
    fi
}
