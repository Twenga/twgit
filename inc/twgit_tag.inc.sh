#!/bin/bash

##
# twgit
#
#
#
# Copyright (c) 2011 Twenga SA
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
# @copyright 2011 Twenga SA
# @copyright 2012 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @license http://www.apache.org/licenses/LICENSE-2.0
#



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
