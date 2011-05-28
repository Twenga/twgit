#!/bin/bash

assert_git_repository

function usage () {
	echo; help 'Usage:'
	help_detail 'twgit tag <action>'
	echo; help 'Available actions are:'
	help_detail '<b>list</b>'
	help_detail '    List 5 last tags. Add <b>-n</b> or <b>--no-fetch</b> to do not pre fetch.'; echo
	help_detail '<b>[help]</b>'
	help_detail '    Display this help.'; echo
}

function cmd_help () {
	usage
	exit 0
}

function cmd_list () {
	if [ "$1" != '-n' -a "$1" != '--no-fetch' ]; then
		processing "git fetch $TWGIT_ORIGIN..."
		git fetch $TWGIT_ORIGIN || die "Could not fetch '$TWGIT_ORIGIN'!"
	fi
	
	local tags=$(get_all_tags)
	if [ -z "$tags" ]; then
		info 'No tag exists.'
		echo
	else
		local tag
		local n=0
		for tag in $tags; do
			info "Tag: $tag"
			git show $tag --pretty=medium | head -n4 | tail -n +2
			let n=$n+1
			[ $n = '5' ] && break 
		done
	fi
}
