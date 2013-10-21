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
    CUI_displayMsg help_detail '<b>list [<demoname>] [-F]</b>'
    CUI_displayMsg help_detail '    List remote demos with their merged features. If <b><demoname></b> is';
    CUI_displayMsg help_detail '    specified, then focus on this demo. Add <b>-F</b> to do not make fetch.'; echo
    CUI_displayMsg help_detail '<b>start <demoname> [-d]</b>'
    CUI_displayMsg help_detail '    Create both a new local and remote demo, or fetch the remote demo,'
    CUI_displayMsg help_detail '    or checkout the local demo. Add <b>-d</b> to delete beforehand local demo'
    CUI_displayMsg help_detail '    if exists.'; echo
    CUI_displayMsg help_detail '<b>remove <demoname></b>'
    CUI_displayMsg help_detail '    Remove both local and remote specified demo branch. No feature will'
    CUI_displayMsg help_detail '    be removed.'; echo
    CUI_displayMsg help_detail '<b>merge-feature <featurename> </b>'
    CUI_displayMsg help_detail '    Try to merge specified feature into current demo.'; echo
    CUI_displayMsg help_detail '<b>status [<demoname>]</b>'
    CUI_displayMsg help_detail '    Display information about specified demo: long name if a connector is'
    CUI_displayMsg help_detail '    setted, last commit, status between local and remote demo and execute'
    CUI_displayMsg help_detail '    a git status if specified demo is the current branch.'
    CUI_displayMsg help_detail '    If no <b><demoname></b> is specified, then use current demo.'; echo
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
# Gère l'option '-c' compactant l'affichage en masquant les détails de commit auteur et date.
#
function cmd_list () {
    process_options "$@"
    require_parameter '-'
    clean_prefixes "$RETVAL" 'demo'
    local demo="$RETVAL"
    local demos

    process_fetch 'F'

    if [ -z "$demo" ]; then
        get_all_demos
        demos="$RETVAL"
        CUI_displayMsg help "Remote demos in progress:"
    else
        demos="$TWGIT_ORIGIN/$TWGIT_PREFIX_DEMO$demo"
        if ! has "$demos" $(get_remote_branches); then
            die "Remote demo '<b>$demos</b>' not found!"
        fi
    fi

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
    clean_prefixes "$RETVAL" 'demo'
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
    clean_prefixes "$RETVAL" 'demo'
    local demo="$RETVAL"
    remove_demo "$demo"
    echo
}

##
# Try to merge specified feature into current demo.
#
# @param string $1 feature to merge in demo
#
function cmd_merge-feature () {
    process_options "$@"
    require_parameter 'feature'
    clean_prefixes "$RETVAL" 'feature'
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

##
# Display information about specified demo: long name if a connector is
# setted, last commit, status between local and remote demo and execute
# a git status if specified demo is the current branch.
# If no <demoname> is specified, then use current demo.
#
# @param string $1 optional demo, if empty then use current demo.
#
function cmd_status() {
    process_options "$@"
    require_parameter '-'
    clean_prefixes "$RETVAL" 'demo'
    local demo="$RETVAL"
    local current_branch=$(get_current_branch)

    # Si demo non spécifiée, récupérer la courante :
    local demo_fullname
    if [ -z "$demo" ]; then
        local all_demos=$(git branch -r | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_DEMO" | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g')
        if ! has "$TWGIT_ORIGIN/$current_branch" $all_demos; then
            die "You must be in a demo if you didn't specify one!"
        fi
        demo_fullname="$current_branch"
    else
        demo_fullname="$TWGIT_PREFIX_DEMO$demo"
        if ! has $demo_fullname $(get_local_branches); then
            die "Local branch '<b>$demo_fullname</b>' does not exist and is required!"
        fi
    fi

    echo
    display_branches 'feature' "$TWGIT_ORIGIN/$demo_fullname"
    echo
    inform_about_branch_status $demo_fullname
    if [ "$demo_fullname" = "$current_branch" ]; then
        exec_git_command "git status" "Error while git status!"
        if [ "$(git config --get color.status)" != 'always' ]; then
            echo
            CUI_displayMsg help "Try this to get colored status in this command: <b>git config --global color.status always</b>"
        fi
    fi
    echo
}
