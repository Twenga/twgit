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
    CUI_displayMsg help_detail '<b>list [-c|-F]</b>'
    CUI_displayMsg help_detail '    List remote demos with merged features.';
    CUI_displayMsg help_detail '    Add <b>-F</b> to do not make fetch, <b>-c</b> to compact display.'; echo
    CUI_displayMsg help_detail '<b>start <demoname> [-d]</b>'
    CUI_displayMsg help_detail '    Create both a new local and remote demo, or fetch the remote demo,'
    CUI_displayMsg help_detail '    or checkout the local demo. Add <b>-d</b> to delete beforehand local demo'
    CUI_displayMsg help_detail '    if exists.'; echo
    CUI_displayMsg help_detail '<b>remove <demoname></b>'
    CUI_displayMsg help_detail '    Remove both local and remote specified demo branch.'; echo
    CUI_displayMsg help_detail '<b>merge-feature <featurename> </b>'
    CUI_displayMsg help_detail '    merge feature on current demo branch.'; echo
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
    if isset_option 'x'; then
        process_fetch 'F' 1>/dev/null
    else
        process_fetch 'F'
    fi

    get_all_demos
    local demos="$RETVAL"
    local add_empty_line=0

    CUI_displayMsg help "Remote demos in progress:"
    if [ ! -z "$demos" ]; then
        for d in $demos; do
            if ! isset_option 'c'; then
                [ "$add_empty_line" = "0" ] && add_empty_line=1 || echo
            fi
            display_demo $d
        done
    else
        CUI_displayMsg info 'No demos exists.'; echo
    fi
}

##
# Crée une nouvelle demo à partir du dernier tag.
# Gère l'option '-d' supprimant préalablement la demo locale, afin de forcer le récréation de la branche.
#
# @param string $1 nom court de la nouvelle demo.
#
function cmd_start () {
    process_options "$@"
    require_parameter 'demo'
    local demo="$RETVAL"
    local demo_fullname="$TWGIT_PREFIX_DEMO$demo"

    assert_valid_ref_name $demo
    assert_clean_working_tree
    process_fetch

    if isset_option 'd'; then
        if has $demo_fullname $(get_local_branches); then
            assert_working_tree_is_not_on_delete_branch $demo_fullname
            remove_local_branch $demo_fullname
        fi
    else
        assert_new_local_branch $demo_fullname
    fi

    CUI_displayMsg processing 'Check remote demos...'
    if has "$TWGIT_ORIGIN/$demo_fullname" $(get_remote_branches); then
        CUI_displayMsg processing "Remote demo '$demo_fullname' detected."
        exec_git_command "git checkout --track -b $demo_fullname $TWGIT_ORIGIN/$demo_fullname" "Could not check out demo '$TWGIT_ORIGIN/$demo_fullname'!"
    else
        assert_tag_exists
        local last_tag=$(get_last_tag)
        exec_git_command "git checkout -b $demo_fullname tags/$last_tag" "Could not check out tag '$last_tag'!"

        local subject="$(getFeatureSubject "$demo")"
        [ ! -z "$subject" ] && subject=": $subject"
        process_first_commit 'feature' "$demo_fullname" "$subject"

        process_push_branch $demo_fullname
        inform_about_branch_status $demo_fullname
    fi
    alert_old_branch $TWGIT_ORIGIN/$demo_fullname with-help
    echo
}

##
#
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

    local all_demos=$(git branch -r --no-merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_DEMO" | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g')
    local current_branch=$(get_current_branch)

    if ! has "$TWGIT_ORIGIN/$current_branch" $all_demos; then
        die "You must be in a demo!"
    else
        echo -n $(CUI_displayMsg question "Are you sure to merge '$TWGIT_ORIGIN/$feature_fullname' into '$TWGIT_ORIGIN/$current_branch'? [Y/N] "); read answer
        [ "$answer" != "Y" ] && [ "$answer" != "y" ] && die 'Merge into current demo aborted!'
    fi

    # Autres tests :
    CUI_displayMsg processing 'Check remote feature...'
    if ! has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches); then
        die "Remote feature '<b>$TWGIT_ORIGIN/$feature_fullname</b>' not found!"
    fi

    # Merge :
    local cmds="$TWGIT_EXEC feature start $feature
git pull $TWGIT_ORIGIN $feature_fullname
$TWGIT_EXEC demo start ${current_branch:${#TWGIT_PREFIX_DEMO}}
git pull $TWGIT_ORIGIN $current_branch
git merge --no-ff $TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE$1
git push $TWGIT_ORIGIN $current_branch"

    IFS="$(echo -e "\n\r")"
    local error=0

    for cmd in $cmds; do
        if [ "$error" -ne 0 ]; then
           CUI_displayMsg help_detail "$cmd"
        else
            [ "${cmd:0:${#TWGIT_EXEC}+1}" = "$TWGIT_EXEC " ] && msg="shell# twgit ${cmd:${#TWGIT_EXEC}+1}" || msg="${TWGIT_GIT_COMMAND_PROMPT}$cmd"
            CUI_displayMsg processing "$msg"
            if ! eval $cmd; then
                error=1
                CUI_displayMsg error "Merge '$feature_fullname' into '$current_branch' aborted!"
                CUI_displayMsg help 'Commands not executed:'
                CUI_displayMsg help_detail "$cmd"
                if [ "${cmd:0:10}" = "git merge " ]; then
                  CUI_displayMsg help_detail "  - resolve conflicts"
                fi
            fi
        fi
    done
    echo
    [ "$error" -eq 0 ] || exit 1

}

