#!/bin/bash

assert_git_repository

function usage {
	echo; help 'Usage:'
	help_detail 'twgit feature <action>'
	echo; help 'Available actions are:'
	help_detail '<b>list</b>     List remote features. Add <b>-n</b> or <b>--no-fetch</b> to do not pre fetch.'
	help_detail '<b>start <featurename></b>'
	help_detail "    Create both a new local and remote feature, or fetch the remote feature."
	help_detail "    Prefix '$TWGIT_PREFIX_FEATURE' will be added to the specified <featurename>."
	help_detail '[help]   Display this help.'
	echo
}

function cmd_help {
	usage
	exit 0
}

function cmd_list {
	if [ "$1" != '-n' -a "$1" != '--no-fetch' ]; then
		processing "git fetch $TWGIT_ORIGIN..."
		git fetch $TWGIT_ORIGIN || die "Could not fetch '$TWGIT_ORIGIN'!"
	fi
		
	local features=$(git branch -r | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
	help "Remote features:"
	if [ -z "$features" ]; then
		info 'No feature branch exists.'
		echo
	else
		local feature
		for feature in $features; do
			info "Feature: $feature"
			git show $feature --pretty=medium | grep -v '^Merge: ' | head -n4
		done
	fi
}

function cmd_start {
	local feature="$1"; require_arg 'feature' "$feature"
	local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"
	
	#checks
	assert_valid_ref_name $feature
	assert_clean_working_tree
	if [ $(has $feature_fullname $(get_local_branches)) = '1' ]; then
		die "Local feature '$feature_fullname' already exists! Pick another name."
	fi
	
	processing "git fetch $TWGIT_ORIGIN --tags..."
	git fetch $TWGIT_ORIGIN --tags || die "Could not fetch '$TWGIT_ORIGIN'!"
	
	processing 'Check remote features...'
	local is_remote_exists=$(has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches))
	if [ $is_remote_exists = '1' ]; then
		processing "Remote feature '$feature_fullname' detected."
	fi	
	
	processing 'Get last tag...'
	local last_tag=$(get_last_tag)
	if [ -z "$last_tag" ]; then
		die 'No tag created!'
	fi
	#local short_last_tag=${last_tag:${#$TWGIT_PREFIX_TAG}}
	
	processing "git checkout -b $feature_fullname $last_tag"
	git checkout -b $feature_fullname $last_tag || die "Could not check out tag '$last_tag'!"
	# Switched to a new branch '$release_fullname'
	
	if [ $is_remote_exists = '0' ]; then
		processing "git push --set-upstream $TWGIT_ORIGIN $feature_fullname"
		git push --set-upstream $TWGIT_ORIGIN $feature_fullname || die "Could not push feature '$feature_fullname'!"
	fi
}
