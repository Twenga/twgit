#!/bin/bash

assert_git_repository

function usage () {
	echo; help 'Usage:'
	help_detail 'twgit feature <action>'
	echo; help 'Available actions are:'
	help_detail '<b>committers <featurename></b>'
	help_detail '    List committers into the specified remote feature.'; echo
	help_detail '<b>list</b>'
	help_detail '    List remote features. Add <b>-n</b> to do not pre fetch.'; echo
	help_detail '<b>remove <featurename></b>'
	help_detail '    Remove both local and remote specified feature branch.'; echo
	help_detail '<b>start <featurename></b>'
	help_detail '    Create both a new local and remote feature, or fetch the remote feature.'
	help_detail "    Prefix '$TWGIT_PREFIX_FEATURE' will be added to the specified <featurename>."; echo
	help_detail '<b>[help]</b>'
	help_detail '    Display this help.'; echo
	# get_rank_contributors origin/master
}

function cmd_help () {
	usage
	exit 0
}

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

function cmd_list () {
	process_options "$@"
	process_fetch 'n'
	
	local features=$(git branch -r --merged $TWGIT_ORIGIN/HEAD | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
	help "Remote features merged into master via releases:"
	if [ -z "$features" ]; then
		info 'No feature branch exists.'; echo
	else
		display_branches 'Feature: ' "$features"
	fi
	
	help "Remote features merged into releases NOT merged into master:"
	local releases=$(git branch -r --no-merged $TWGIT_ORIGIN/HEAD | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_RELEASE" | sed 's/^[* ]*//')
	if [ -z "$releases" ]; then
		info 'No release branch NOT merged exists.'; echo
	else	
		for release in $releases; do
			info "<b>Release '$release':</b>"
			local features=$(git branch -r --merged $release | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
			if [ -z "$features" ]; then
				info 'No feature branch exists.'; echo
			else
				display_branches 'Feature: ' "$features"
			fi
		done
	fi
	
	local features=$(git branch -r | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
	help "Remote features not finished:"
	if [ -z "$features" ]; then
		info 'No feature branch exists.'; echo
	else
		display_branches 'Feature: ' "$features"
	fi	
}

function cmd_start () {
	process_options "$@"
	require_parameter 'feature'
	local feature="$RETVAL"
	local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"
	
	assert_valid_ref_name $feature
	assert_clean_working_tree
	assert_new_local_branch $feature_fullname
	
	process_fetch
	
	processing 'Check remote features...'
	local is_remote_exists=$(has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches) && echo 1 || echo 0)
	if [ $is_remote_exists = '1' ]; then
		processing "Remote feature '$feature_fullname' detected."
	fi	
	
	assert_tag_exists
	local last_tag=$(get_last_tag)
	#local short_last_tag=${last_tag:${#$TWGIT_PREFIX_TAG}}
	
	processing "${TWGIT_GIT_COMMAND_PROMPT}git checkout -b $feature_fullname $last_tag"
	git checkout -b $feature_fullname $last_tag || die "Could not check out tag '$last_tag'!"
	
	process_first_commit 'feature' "$feature_fullname"
	process_push_branch $feature_fullname $is_remote_exists
}

function cmd_remove () {
	process_options "$@"
	require_parameter 'feature'
	local feature="$RETVAL"
	local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"
	
	assert_valid_ref_name $feature
	assert_working_tree_is_not_to_delete_branch $feature_fullname
	
	process_fetch
	remove_local_branch $feature_fullname
	remove_remote_branch $feature_fullname
}
