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
	help_detail '<b>remove <featurename></b>'
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
		echo
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
	
	local features=$(git branch -r --merged $TWGIT_ORIGIN/HEAD | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
	help "Remote features merged into master:"
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
	
	help "Remote features merged into releases NOT merged into master:"
	local releases=$(git branch -r --no-merged $TWGIT_ORIGIN/HEAD | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_RELEASE" | sed 's/^[* ]*//')
	if [ -z "$releases" ]; then
		info 'No release branch NOT merged exists.'
		echo
	else	
		local release
		for release in $releases; do
			help "Remote features merged into '$release' NOT merged into master:"
			local features=$(git branch -r --merged $release | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
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
	
	local commit_msg=$(printf "$TWGIT_FIRST_COMMIT_MSG" "feature" "$feature_fullname")
	processing "git commit --allow-empty -am \"$commit_msg\""
	git commit --allow-empty -am "$commit_msg" || die "Could not make init commit!"
	
	local git_options=$([ $is_remote_exists = '0' ] && echo '--set-upstream' || echo '')
	processing "git push $git_options $TWGIT_ORIGIN $feature_fullname"
	git push $git_options $TWGIT_ORIGIN $feature_fullname || die "Could not push feature '$feature_fullname'!"
}

function cmd_remove {
	local feature="$1"; require_arg 'feature' "$feature"
	local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"
	
	assert_valid_ref_name $feature
	
	processing "git fetch $TWGIT_ORIGIN --tags..."
	git fetch $TWGIT_ORIGIN --tags || die "Could not fetch '$TWGIT_ORIGIN'!"
	
	if [ $(has $feature_fullname $(get_local_branches)) = '1' ]; then
		processing "git branch -D $feature_fullname"
		git branch -D $feature_fullname || die "Remove local feature '$feature_fullname' failed!"
	else
		processing "Local feature '$feature_fullname' not found."
	fi
	
	if [ $(has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches)) = '1' ]; then
		processing "git push $TWGIT_ORIGIN :$feature_fullname"
		git push $TWGIT_ORIGIN :$feature_fullname
		if [ $? -ne 0 ]; then
			processing "Remove remote feature '$TWGIT_ORIGIN/$feature_fullname' failed! Maybe already deleted... so:"
			processing "git remote prune $TWGIT_ORIGIN"
			git remote prune $TWGIT_ORIGIN || die "Prune failed!"
		fi
	else
		die "Remote feature '$TWGIT_ORIGIN/$feature_fullname' not found!"
	fi	
}
