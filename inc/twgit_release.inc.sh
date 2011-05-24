#!/bin/bash

assert_git_repository

function usage {
	echo; help 'Usage:'
	help_detail 'twgit release [list] [-v]'
	help_detail "twgit release start [-F] <name> [<base>]"
	help_detail 'twgit release finish [-rFk] [<name|nameprefix>]'
	help_detail 'twgit release publish <name>'
	help_detail 'twgit release track <name>'
	help_detail 'twgit release diff [<name|nameprefix>]'
	help_detail 'twgit release rebase [-i] [<name|nameprefix>]'
	help_detail 'twgit release checkout [<name|nameprefix>]'
	help_detail 'twgit release pull <remote> [<name>]'
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
	
	processing 'Git fetch...'
	git fetch --tags
	
	local last_tag=$(get_last_tag)
	if [ -z "$last_tag" ]; then
		die 'No tag created!'
	fi
	
	processing 'Git checkout ...'
	#git push $TWGIT_ORIGIN tag:$release_fullname
	
	
	
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
