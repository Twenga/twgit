#!/bin/bash

##
# twgit
#
#
#
# Copyright (c) 2013 Geoffroy Aubry <geoffroy.aubry@free.fr>
# Copyright (c) 2013 Cyrille Hemidy
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
# @copyright 2013 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @copyright 2013 Cyrille Hemidy
# @license http://www.apache.org/licenses/LICENSE-2.0
#



##
# Affiche l'aide de la commande demo.
#
function usage () {
    echo; CUI_displayMsg help 'Usage:'
    CUI_displayMsg help_detail '<b>twgit demo <action></b>'
    echo; CUI_displayMsg help 'Available actions are:'
    CUI_displayMsg help_detail '<b>list [-F]</b>'
    CUI_displayMsg help_detail '    List remote demos with merged features.';
    CUI_displayMsg help_detail '    Add <b>-F</b> to do not make fetch.'; echo
    CUI_displayMsg help_detail '<b>start <demoname> [-d]</b>'
    CUI_displayMsg help_detail '    Create both a new local and remote demo, or fetch the remote demo,'
    CUI_displayMsg help_detail '    or checkout the local demo. Add <b>-d</b> to delete beforehand local demo'
    CUI_displayMsg help_detail '    if exists.'; echo
    CUI_displayMsg help_detail '<b>remove <demoname></b>'
    CUI_displayMsg help_detail '    Remove both local and remote specified demo branch. No feature will'
    CUI_displayMsg help_detail '    be removed.'; echo
    CUI_displayMsg help_detail '<b>merge-feature <featurename> </b>'
    CUI_displayMsg help_detail '    Try to merge specified feature into current demo.'; echo
    CUI_displayMsg help_detail "Prefix '$TWGIT_PREFIX_DEMO' will be added to <b><demoname></b> parameter."; echo
    CUI_displayMsg help_detail '<b>[help]</b>'
    CUI_displayMsg help_detail '    Display this help.'; echo
}

##
# Action déclenchant l'affichage de l'aide.
#
function cmd_help () {
    usage;
}

##
# Liste les branches de demo.
# Détaille les features incluses dans chaque branche demo.
# Gère l'option '-F' permettant d'éviter le fetch.
#
function cmd_list () {
    process_options "$@"
    require_parameter '-'
    local demo="$RETVAL"

    process_fetch 'F'

    if [ -z "$demo" ]; then
      get_all_demos
      local demos="$RETVAL"
    else
      local demos="$TWGIT_ORIGIN/$TWGIT_PREFIX_DEMO$demo"
    fi

    CUI_displayMsg help "Remote demos in progress:"
    if [ ! -z "$demos" ]; then
        local add_empty_line=0
        local origin_prefix="$TWGIT_ORIGIN/"
        for d in $demos; do
            if ! isset_option 'c'; then
                [ "$add_empty_line" = "0" ] && add_empty_line=1 || echo
            fi
            display_super_branch 'demo' "${d:${#origin_prefix}}"
        done
    else
        display_branches 'demo' ''
    fi
    echo
}

##
# Crée une nouvelle demo à partir du dernier tag.
# Gère l'option '-d' supprimant préalablement la demo locale, afin de forcer le recréation de la branche.
#
# @param string $1 nom court de la nouvelle demo.
#
function cmd_start () {
    process_options "$@"
    require_parameter 'demo'
    local demo="$RETVAL"
    start_simple_branch "$demo" "$TWGIT_PREFIX_DEMO"
    echo
}

##
# Suppression de la démo spécifiée.
#
# @param string $1 nom court de la démo à supprimer
#
function cmd_remove () {
    process_options "$@"
    require_parameter 'demo'
    local demo="$RETVAL"
    remove_demo "$demo"
    echo
}

##
#
#
function cmd_merge-feature () {
    process_options "$@"
    require_parameter 'feature'
    local feature="$RETVAL"
    local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"

    # Tests préliminaires :
    assert_clean_working_tree
    process_fetch

    get_all_demos
    local all_demos="$RETVAL"
    local current_branch=$(get_current_branch)

    if ! has "$TWGIT_ORIGIN/$current_branch" $all_demos; then
        die "You must be in a demo!"
    fi

    merge_feature_into_branch "$feature" "$current_branch"
}

