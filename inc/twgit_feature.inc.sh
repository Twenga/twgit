#!/bin/bash

assert_git_repository

##
# Affiche l'aide de la commande tag.
#
function usage () {
	echo; help 'Usage:'
	help_detail 'twgit feature <action>'
	echo; help 'Available actions are:'
	help_detail '<b>committers <featurename></b>'
	help_detail '    List committers into the specified remote feature.'; echo
	help_detail '<b>list</b>'
	help_detail '    List remote features. Add <b>-f</b> to do not make fetch.'; echo
	help_detail '<b>remove <featurename></b>'
	help_detail '    Remove both local and remote specified feature branch.'; echo
	help_detail '<b>start <featurename></b>'
	help_detail '    Create both a new local and remote feature, or fetch the remote feature,'
	help_detail '    or checkout the local feature.'
	help_detail "    Prefix '$TWGIT_PREFIX_FEATURE' will be added to the specified <featurename>."; echo
	help_detail '<b>[help]</b>'
	help_detail '    Display this help.'; echo
}

##
# Action déclenchant l'affichage de l'aide.
#
function cmd_help () {
	usage
}

##
# Liste les personnes ayant committé sur la feature.
#
# @param string $1 nom court de la feature
#
function cmd_committers () {
	process_options "$@"
	require_parameter 'feature'
	local feature="$RETVAL"
	local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"

	process_fetch; echo

	if has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches); then
		info "Committers into '$TWGIT_ORIGIN/$feature_fullname' remote feature:"
		get_rank_contributors "$TWGIT_ORIGIN/$feature_fullname"
		echo
	else
		die "Unknown remote feature '$feature_fullname'."
	fi
}

##
# Liste les features et leur statut par rapport aux releases.
# Gère l'option '-f' permettant d'éviter le fetch.
#
function cmd_list () {
	process_options "$@"
	process_fetch 'f'
	local features

	features=$(git branch -r --merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
	if [ ! -z "$features" ]; then
		help "Remote features merged into '<b>$TWGIT_STABLE</b>' via releases:"
		warn 'They would not exists!'
		display_branches 'Feature: ' "$features"
	fi

	local release=$(get_current_release_in_progress)
	if [ -z "$release" ]; then
		help "Remote features merged into release in progress:"
		info 'No such branch exists.'; echo
	else
		help "Remote features merged into release in progress '<b>$release</b>':"
		features=$(get_merged_features $release)
		display_branches 'Feature: ' "$features"

		features="$(get_features merged_in_progress $release)"
		help "Remote features in progress, merged into '<b>$release</b>' in the past:"
		display_branches 'Feature: ' "$features"
	fi

	features="$(get_features free $release)"
	help "Remote free features:"
	display_branches 'Feature: ' "$features"
}

##
# Crée une nouvelle feature à partir du dernier tag.
#
# @param string $1 nom court de la nouvelle feature.
#
function cmd_start () {
	process_options "$@"
	require_parameter 'feature'
	local feature="$RETVAL"
	local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"

	assert_valid_ref_name $feature
	assert_new_local_branch $feature_fullname
	assert_clean_working_tree

	process_fetch

	processing 'Check remote features...'
	if has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches); then
		processing "Remote feature '$feature_fullname' detected."
		exec_git_command "git checkout --track -b $feature_fullname $TWGIT_ORIGIN/$feature_fullname" "Could not check out feature '$TWGIT_ORIGIN/$feature_fullname'!"
	else
		assert_tag_exists
		local last_tag=$(get_last_tag)
		exec_git_command "git checkout --track -b $feature_fullname $last_tag" "Could not check out tag '$last_tag'!"
		process_first_commit 'feature' "$feature_fullname"
		process_push_branch $feature_fullname
	fi
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
}
