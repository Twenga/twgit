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
    echo; CUI_displayMsg help 'Usage:'
    CUI_displayMsg help_detail '<b>twgit tag <action></b>'
    echo; CUI_displayMsg help 'Available actions are:'
    CUI_displayMsg help_detail '<b>list [<tagname>] [-F]</b>'
    CUI_displayMsg help_detail '    List 5 last tags with included features. Add <b>-F</b> to do not make fetch.'
    CUI_displayMsg help_detail '    If <b><tagname></b> is specified (using major.minor.revision format), then'
    CUI_displayMsg help_detail '    focus on this tag.'; echo
    CUI_displayMsg help_detail '<b>[help]</b>'
    CUI_displayMsg help_detail '    Display this help.'; echo
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
# Liste les derniers tags ou l'un en particulier si spécifié.
# Détaille les features incluses dans la release à la source du tag.
# Gère l'option '-F' permettant d'éviter le fetch.
#
# @param string $1 nom court optionnel d'un tag
# @testedby TwgitTagTest
#
function cmd_list () {
    process_options "$@"
    require_parameter '-'
    local tag="$RETVAL"
    local tag_fullname="$TWGIT_PREFIX_TAG$tag"
    process_fetch 'F'

    if [ ! -z "$tag" ]; then
        assert_valid_tag_name "$tag"
        ! has "$tag_fullname" $(get_all_tags) && die "Tag '<b>$tag_fullname</b>' does not exist! Try: twgit tag list"
        echo
        displayTag "$tag_fullname"
        echo
    else
        local max='150'
        local tags=$(get_all_tags $max)
        CUI_displayMsg help "List $max last tags:"
        if [ -z "$tags" ]; then
            CUI_displayMsg info 'No tag exists.'; echo
        else
            for tag_fullname in $tags; do
                displayTag "$tag_fullname"
                echo
            done
        fi
    fi
}
