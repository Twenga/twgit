#!/bin/bash

assert_git_repository

function usage {
	echo; help 'Usage:'
	help_detail 'twgit feature [list] [-v]'
	help_detail "twgit feature start [-F] <name> [<base>]"
	help_detail 'twgit feature finish [-rFk] [<name|nameprefix>]'
	help_detail 'twgit feature publish <name>'
	help_detail 'twgit feature track <name>'
	help_detail 'twgit feature diff [<name|nameprefix>]'
	help_detail 'twgit feature rebase [-i] [<name|nameprefix>]'
	help_detail 'twgit feature checkout [<name|nameprefix>]'
	help_detail 'twgit feature pull <remote> [<name>]'
	echo
}

function cmd_help {
	usage
	exit 0
}

function cmd_list {
	local feature_branches=$(echo "$(get_local_branches)" | grep "^$TWGIT_PREFIX_FEATURE")
	if [ -z "$feature_branches" ]; then
		info 'No feature branch exists.'
		echo
		help 'You can start a new feature branch:'
		help_detail 'git flow feature start <name> [<base>]'
		echo
	else
		echo $feature_branches
	fi
}

function cmd_start {
	local branch="$1"
	require_arg 'branch' "$branch"
	local branch_fullname="$TWGIT_PREFIX_FEATURE$branch"
	
	assert_clean_working_tree
	if has $branch_fullname $(get_local_branches); then
		die "Local feature '$branch' already exists. Pick another name."
	fi
	
#	local errormsg=$(git rev-parse --git-dir 2>&1)
#	[ $? ] && die "[Git error msg] $errormsg"
#	if ! git checkout -b "$branch" "$BASE"; then
#		die "Could not create feature branch '$BRANCH'"
#	fi
}