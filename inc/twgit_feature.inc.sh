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

##
# Affiche l'aide de la commande tag.
#
# @testedby TwgitHelpTest
#
function usage () {
    echo; help 'Usage:'
    help_detail '<b>twgit feature <action></b>'
    echo; help 'Available actions are:'
    help_detail '<b>committers <featurename> [<max>] [-F]</b>'
    help_detail '    List first <b><max></b> committers into the specified remote feature.'
    help_detail "    Default value of <b><max></b>: $TWGIT_DEFAULT_NB_COMMITTERS. Add <b>-F</b> to do not make fetch."; echo
    help_detail '<b>list [-c|-F|-x]</b>'
    help_detail '    List remote features. Add <b>-F</b> to do not make fetch, <b>-c</b> to compact display'
    help_detail '    and <b>-x</b> (eXtremely compact) to CSV display.'; echo
    help_detail '<b>merge-into-release [<featurename>]</b>'
    help_detail '    Try to merge specified feature into current release.'
    help_detail '    If no <b><featurename></b> is specified, then ask to use current feature.'; echo
    help_detail '<b>migrate <oldfeaturefullname> <newfeaturename></b>'
    help_detail '    Migrate old branch to new process.'
    help_detail '    For example: "twgit feature migrate rm7880 7880"'; echo
    help_detail '<b>remove <featurename></b>'
    help_detail '    Remove both local and remote specified feature branch.'; echo
    help_detail '<b>show-modified-files [<featurename>]</b>'
    help_detail '    List created/modified/deleted files of the specified feature branch since'
    help_detail '    its creation (from commits). If no <b><featurename></b> is specified, then use'
    help_detail '    current feature.'; echo
    help_detail '<b>start <featurename> [-d]</b>'
    help_detail '    Create both a new local and remote feature, or fetch the remote feature,'
    help_detail '    or checkout the local feature. Add <b>-d</b> to delete beforehand local feature'
    help_detail '    if exists.'
    help_detail "    Prefix '$TWGIT_PREFIX_FEATURE' will be added to the specified <b><featurename></b>."; echo
    help_detail '<b>status [<featurename>]</b>'
    help_detail '    Display information about specified feature: long name if a connector is'
    help_detail '    setted, last commit, status between local and remote feature and execute'
    help_detail '    a git status if specified feature is the current branch.'
    help_detail '    If no <b><featurename></b> is specified, then use current feature.'; echo
    help_detail '<b>[help]</b>'
    help_detail '    Display this help.'; echo
}

##
# Action déclenchant l'affichage de l'aide.
#
# @testedby TwgitHelpTest
#
function cmd_help () {
    usage
}

##
# Liste les personnes ayant le plus committé sur la feature spécifiée.
# Gère l'option '-F' permettant d'éviter le fetch.
#
# @param string $1 nom court de la feature
# @param int $2 nombre de committers à afficher au maximum, optionnel
#
function cmd_committers () {
    process_options "$@"

    require_parameter 'feature'
    local feature="$RETVAL"
    local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"

    require_parameter '-'
    local max="$RETVAL"

    process_fetch 'F'

    if has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches); then
        display_rank_contributors "$feature_fullname" "$max"
    else
        die "Unknown remote feature '$feature_fullname'."
    fi
}

##
# Liste les features et leur statut par rapport aux releases.
# Gère l'option '-F' permettant d'éviter le fetch.
# Gère l'option '-c' compactant l'affichage en masquant les détails de commit auteur et date.
# Gère l'option '-x' (eXtremely compact) retournant un affichage CVS.
#
function cmd_list () {
    process_options "$@"
    if isset_option 'x'; then
        process_fetch 'F' 1>/dev/null
    else
        process_fetch 'F'
    fi

    local features
    local prefix="$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE"
    features=$(git branch -r --merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
    if isset_option 'x'; then
        display_csv_branches "$features" "merged into stable"
    elif [ ! -z "$features" ]; then
        help "Remote features merged into '<b>$TWGIT_STABLE</b>' via releases:"
        warn 'They would not exists!'
        display_branches 'feature' "$features"; echo
    fi

    local release="$(get_current_release_in_progress)"
    if [ -z "$release" ]; then
        if ! isset_option 'x'; then
            help "Remote delivered features merged into release in progress:"
            info 'No such branch exists.'; echo
        fi
    else
        get_merged_features $release
        local features_merged="$GET_MERGED_FEATURES_RETURN_VALUE"

        get_features merged_in_progress $release
        local features_in_progress="$GET_FEATURES_RETURN_VALUE"

        if isset_option 'x'; then
            display_csv_branches "$features_merged" "merged into release"
            display_csv_branches "$features_in_progress" "merged into release, then in progress"
        else
            help "Remote delivered features merged into release in progress '<b>$TWGIT_ORIGIN/$release</b>':"
            display_branches 'feature' "$features_merged"; echo
            help "Remote features in progress, previously merged into '<b>$TWGIT_ORIGIN/$release</b>':"
            display_branches 'feature' "$features_in_progress"; echo
        fi
    fi

    get_features free $release
    features="$GET_FEATURES_RETURN_VALUE"

    if isset_option 'x'; then
        display_csv_branches "$features" "free"
    else
        help "Remote free features:"
        display_branches 'feature' "$features"; echo
        alert_dissident_branches
    fi
}

##
# Migre une branche de dév de l'ancien workflow dans le présent, tout en préservant l'historique.
# Typiquement : rmxxxx => feature-xxxx
#
# @param string $1 nom complet de la branche de dév à migrer
# @param string $2 nom court de la future feature (c.-à-d. sans le préfix 'feature-')
#
function cmd_migrate () {
    process_options "$@"
    require_parameter 'oldfeaturefullname'
    local oldfeature_fullname="$RETVAL"
    require_parameter 'newfeaturename'
    local feature="$RETVAL"
    local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"

    assert_valid_ref_name $feature
    assert_clean_working_tree

    processing 'Check local features...'
    if has $feature_fullname $(get_local_branches); then
        die "Local branch '$feature_fullname' already exists!"
    fi

    process_fetch
    processing 'Check remote features...'
    if ! has "$TWGIT_ORIGIN/$oldfeature_fullname" $(get_remote_branches); then
        die "Remote branch '$TWGIT_ORIGIN/$oldfeature_fullname' does not exist!"
    elif has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches); then
        die "Remote feature '$feature_fullname' already exists!"
    fi

    echo -n $(question "Are you sure to migrate '$oldfeature_fullname' to '$feature_fullname'? Branch '$oldfeature_fullname' will be deleted. [Y/N] "); read answer
    [ "$answer" != "Y" ] && [ "$answer" != "y" ] && die 'Branch migration aborted!'

    processing "Migrate '<b>$oldfeature_fullname</b>' to '<b>$feature_fullname</b>'..."
    exec_git_command "git checkout --track -b $feature_fullname $TWGIT_ORIGIN/$oldfeature_fullname" "Could not check out feature '$TWGIT_ORIGIN/$oldfeature_fullname'!"
    remove_local_branch "$oldfeature_fullname"
    remove_remote_branch "$oldfeature_fullname"
    exec_git_command "git merge --no-ff $TWGIT_STABLE" "Could not merge stable into '$feature_fullname'!"
    process_push_branch "$feature_fullname"
}

##
# Crée une nouvelle feature à partir du dernier tag.
# Gère l'option '-d' supprimant préalablement la feature locale, afin de forcer le récréation de la branche.
#
# @param string $1 nom court de la nouvelle feature.
#
function cmd_start () {
    process_options "$@"
    require_parameter 'feature'
    local feature="$RETVAL"
    local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"

    assert_valid_ref_name $feature
    assert_clean_working_tree
    process_fetch

    if isset_option 'd'; then
        if has $feature_fullname $(get_local_branches); then
            assert_working_tree_is_not_on_delete_branch $feature_fullname
            remove_local_branch $feature_fullname
        fi
    else
        assert_new_local_branch $feature_fullname
    fi

    processing 'Check remote features...'
    if has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches); then
        processing "Remote feature '$feature_fullname' detected."
        exec_git_command "git checkout --track -b $feature_fullname $TWGIT_ORIGIN/$feature_fullname" "Could not check out feature '$TWGIT_ORIGIN/$feature_fullname'!"
    else
        assert_tag_exists
        local last_tag=$(get_last_tag)
        exec_git_command "git checkout -b $feature_fullname tags/$last_tag" "Could not check out tag '$last_tag'!"
        process_first_commit 'feature' "$feature_fullname"

        local subject="$(getFeatureSubject "$feature")"
        [ ! -z "$subject" ] && subject=": $subject"
        process_first_commit 'feature' "$feature_fullname" "$subject"

        process_push_branch $feature_fullname
        inform_about_branch_status $feature_fullname
    fi
    alert_old_branch $TWGIT_ORIGIN/$feature_fullname with-help
    echo
}

##
# Affiche des informations sur la feature courante :
# - nom long si un connecteur est configuré,
# - info sur le dernier commit,
# - info et conseil sur le statut de la version locale par rapport la distante,
# - un git status si la feature fournie est celle courante.
# Aucun git fetch n'est effectué.
#
# @param string $1 l'éventuelle feature pour la demande de status, sinon la feature courante est utilisée
#
function cmd_status () {
    process_options "$@"
    require_parameter '-'
    local feature="$RETVAL"
    local current_branch=$(get_current_branch)

    # Si feature non spécifiée, récupérer la courante :
    local feature_fullname
    if [ -z "$feature" ]; then
        local all_features=$(git branch -r | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g')
        if ! has "$TWGIT_ORIGIN/$current_branch" $all_features; then
            die "You must be in a feature if you didn't specify one!"
        fi
        feature_fullname="$current_branch"
    else
        feature_fullname="$TWGIT_PREFIX_FEATURE$feature"
        if ! has $feature_fullname $(get_local_branches); then
            die "Local branch '<b>$feature_fullname</b>' does not exist and is required!"
        fi
    fi

    echo
    display_branches 'feature' "$TWGIT_ORIGIN/$feature_fullname"
    echo
    inform_about_branch_status $feature_fullname
    if [ "$feature_fullname" = "$current_branch" ]; then
        exec_git_command "git status" "Error while git status!"
        if [ "$(git config --get color.status)" != 'always' ]; then
            echo
            help "Try this to get colored status in this command: <b>git config --global color.status always</b>"
        fi
    fi
    echo
}

##
# Merge la feature spécifiée dans la release en cours.
#
# @param string $1 l'éventuelle feature à merger dans la release en cours, sinon la feature courante est utilisée
#
function cmd_merge-into-release () {
    process_options "$@"
    require_parameter '-'
    local feature="$RETVAL"

    # Récupération de la release en cours :
    local release_fullname=$(get_current_release_in_progress)
    local release="${release_fullname:${#TWGIT_PREFIX_RELEASE}}"

    # Tests préliminaires :
    assert_clean_working_tree
    process_fetch
    processing 'Check remote release...'
    [ -z "$release" ] && die 'No release in progress!'

    # Si feature non spécifiée, récupérer la courante :
    local feature_fullname
    if [ -z "$feature" ]; then
        local all_features=$(git branch -r --no-merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g')
        local current_branch=$(get_current_branch)
        if ! has "$TWGIT_ORIGIN/$current_branch" $all_features; then
            die "You must be in a feature if you didn't specify one!"
        else
            echo -n $(question "Are you sure to merge '$TWGIT_ORIGIN/$current_branch' into '$TWGIT_ORIGIN/$release_fullname'? [Y/N] "); read answer
            [ "$answer" != "Y" ] && [ "$answer" != "y" ] && die 'Merge into current release aborted!'
        fi
        feature_fullname="$current_branch"
        feature="${feature_fullname:${#TWGIT_PREFIX_FEATURE}}"
    else
        feature_fullname="$TWGIT_PREFIX_FEATURE$feature"
    fi

    # Autres tests :
    processing 'Check remote feature...'
    if ! has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches); then
        die "Remote feature '$TWGIT_ORIGIN/$feature_fullname' not found!"
    fi

    # Merge :
    local cmds="$TWGIT_EXEC feature start $feature
git pull $TWGIT_ORIGIN $feature_fullname
$TWGIT_EXEC release start
git pull $TWGIT_ORIGIN $release_fullname
git merge --no-ff $feature_fullname
git push $TWGIT_ORIGIN $release_fullname"
    IFS="$(echo -e "\n\r")"
    local error=0
    local prefix
    for cmd in $cmds; do
        if [ "$error" -ne 0 ]; then
            help_detail "$cmd"
        else
            [ "${cmd:0:${#TWGIT_EXEC}+1}" = "$TWGIT_EXEC " ] && msg="shell# twgit ${cmd:${#TWGIT_EXEC}+1}" || msg="${TWGIT_GIT_COMMAND_PROMPT}$cmd"
            processing "$msg"
            if ! eval $cmd; then
                error=1
                error "Merge '$feature_fullname' into '$release_fullname' aborted!"
                help 'Commands not executed:'
                help_detail "$cmd"
                if [ "${cmd:0:10}" = "git merge " ]; then
                    help_detail "  - resolve conflicts"
                    help_detail "  - git add..."
                    help_detail "  - git commit..."
                fi
            fi
        fi
    done
    echo
    [ "$error" -eq 0 ] || exit 1
}

##
# Suppression de la feature spécifiée.
#
# @param string $1 nom court de la feature à supprimer
#
function cmd_remove () {
    process_options "$@"
    require_parameter 'feature'
    local feature="$RETVAL"
    remove_feature "$feature"
    echo
}

##
# Liste les fichiers créés, modifiés ou supprimés dans la feature spécifiée depuis sa création,
# en inspectant les commits.
#
# @param string $1 l'éventuelle feature à analyser, sinon la feature courante sera utilisée
#
function cmd_show-modified-files () {
    process_options "$@"
    require_parameter '-'
    local feature="$RETVAL"

    if [ ! -z "$feature" ]; then
        feature_fullname="$TWGIT_PREFIX_FEATURE$feature"
        processing 'Check remote feature...'
        if ! has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches); then
            die "Remote feature '$TWGIT_ORIGIN/$feature_fullname' not found!"
        fi
        $TWGIT_EXEC feature start $feature || die "Unable to start '$feature' feature!"
    else
        local all_features=$(git branch -r --no-merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g')
        local current_branch=$(get_current_branch)
        if ! has "$TWGIT_ORIGIN/$current_branch" $all_features; then
            die "You must be in a feature if you don't specified one!"
        fi
        feature_fullname="$current_branch"
        feature="${feature_fullname:${#TWGIT_PREFIX_FEATURE}}"
    fi

    local commit_msg=$(printf "$TWGIT_FIRST_COMMIT_MSG" "feature" "$feature_fullname")
    local start_sha1=$(git log --fixed-strings --grep="$commit_msg" --pretty="format:%H")
    local modified_files="$(git show --pretty="format:" --name-only $start_sha1..HEAD | sort | uniq | sed '/^$/d')"
    local count="$(echo "$modified_files" | sed '/^$/d' | wc -l)"

    info "SHA1 of creation of '$feature_fullname':"
    echo $start_sha1; echo

    info "Number of created/modified/deleted files of '$feature_fullname' since its creation:"
    echo "$count"; echo

    if [ "$count" != '0' ]; then
        info "List of these files:"
        echo "$modified_files"; echo
    fi
}
