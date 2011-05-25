#!/bin/bash

assert_git_repository

function usage {
	echo; help 'Usage:'
	help_detail 'twgit tag <action>'
	echo; help 'Available actions are:'
	help_detail '<b>list</b>     ...'
	help_detail '[help]   Display this help.'
	echo
}

function cmd_help {
	usage
	exit 0
}

function cmd_list {
	processing "git fetch $TWGIT_ORIGIN --tags..."
	git fetch $TWGIT_ORIGIN --tags || die "Could not fetch '$TWGIT_ORIGIN'!"
	
	local tags=$(get_all_tags)
	if [ -z "$tags" ]; then
		info 'No tag exists.'
		echo
	fi
	
	local tag
	for tag in $tags; do
		git show $tag --pretty=medium | head -n4
	done
}
