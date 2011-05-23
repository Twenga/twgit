#!/bin/bash

assert_git_repository

function help {
	echo "usage: git flow feature [list] [-v]"
	echo "       git flow feature start [-F] <name> [<base>]"
	echo "       git flow feature finish [-rFk] [<name|nameprefix>]"
	echo "       git flow feature publish <name>"
	echo "       git flow feature track <name>"
	echo "       git flow feature diff [<name|nameprefix>]"
	echo "       git flow feature rebase [-i] [<name|nameprefix>]"
	echo "       git flow feature checkout [<name|nameprefix>]"
	echo "       git flow feature pull <remote> [<name>]"
}

function cmd_help {
	help
	exit 0
}

function cmd_list {
	local feature_branches=$(echo "$(get_local_branches)" | grep "^$TWGIT_PREFIX_FEATURE")
	if [ -z "$feature_branches" ]; then
		echo "No feature branches exist."
		echo ""
		echo "You can start a new feature branch:"
		echo ""
		echo "    git flow feature start <name> [<base>]"
		echo ""
	fi
	echo $feature_branches
	echo ">>`get_current_branch`"
}

function cmd_start {
	local branch="$1"
	if [ -z "$branch" ]; then
		echo "Missing argument <name>"
		help
		exit 1
	fi
	assert_branch_absent "$branch"
}