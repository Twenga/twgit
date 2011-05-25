#!/bin/bash

assert_git_repository

function usage {
	echo; help 'Usage:'
	help_detail 'twgit release <action>'
	echo; help 'Available actions are:'
	help_detail '<b>list</b>     ...'
	help_detail '<b>start</b>    ...'
	help_detail '[help]   Display this help.'
	echo
}

function cmd_help {
	usage
	exit 0
}

function cmd_list {
	local tags=$(get_all_tags)
	if [ -z "$tags" ]; then
		info 'No tag exists.'
		echo
		help 'You can start a new feature branch:'
		help_detail 'git flow feature start <name> [<base>]'
		echo
	else
		echo $tags
	fi
}

function cmd_start {
	local release="$1"
	require_arg 'release' "$release"
	local release_fullname="$TWGIT_PREFIX_RELEASE$release"
	
	#checks
	assert_valid_release_name $release
	assert_clean_working_tree
	if has $release_fullname $(get_local_branches); then
		die "Local release '$release_fullname' already exists! Pick another name."
	fi
	
	processing "git fetch $TWGIT_ORIGIN --tags..."
	git fetch $TWGIT_ORIGIN --tags || die "Could not fetch '$TWGIT_ORIGIN'!"
	
	local last_tag=$(get_last_tag)
	if [ -z "$last_tag" ]; then
		die 'No tag created!'
	fi
	#local short_last_tag=${last_tag:${#$TWGIT_PREFIX_TAG}}
	
	processing "git checkout -b $release_fullname $last_tag"
	git checkout -b $release_fullname $last_tag || die "Could not check out tag '$last_tag'!"
	# Switched to a new branch '$release_fullname'
	
	processing "git push --set-upstream $TWGIT_ORIGIN $release_fullname"
	git push --set-upstream $TWGIT_ORIGIN $release_fullname || die "Could not push release '$release_fullname'!"
	
	
# git merge-base "`git rev-parse 'tests_git'`" "`git rev-parse 'origin/tests_git'`"	

#	local errormsg=$(git rev-parse --git-dir 2>&1)
#	[ $? ] && die "[Git error msg] $errormsg"
#	if ! git checkout -b "$branch" "$BASE"; then
#		die "Could not create feature branch '$BRANCH'"
#	fi
}

function cmd_finish {
	:
}
