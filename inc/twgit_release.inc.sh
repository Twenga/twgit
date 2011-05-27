#!/bin/bash

assert_git_repository

function usage {
	echo; help 'Usage:'
	help_detail 'twgit release <action>'
	echo; help 'Available actions are:'
	help_detail '<b>list</b>     List remote releases. Add <b>-n</b> or <b>--no-fetch</b> to do not pre fetch.'
	help_detail '<b>start <releasename></b>'
	help_detail "    Create both a new local and remote release, or fetch the remote release."
	help_detail "    Prefix '$TWGIT_PREFIX_RELEASE' will be added to the specified <releasename>."
	help_detail '<b>finish <releasename> <tagname></b>'
	help_detail '<b>remove <releasename></b>'
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
	
	local releases=$(git branch -r --merged $TWGIT_ORIGIN/HEAD | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_RELEASE" | sed 's/^[* ]*//')
	help "Remote releases merged into master:"
	if [ -z "$releases" ]; then
		info 'No merged release branch exists.'
		echo
	else
		local release
		for release in $releases; do
			info "Release: $release"
			git show $release --pretty=medium | head -n4
		done
	fi
		
	local releases=$(git branch -r --no-merged $TWGIT_ORIGIN/HEAD | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_RELEASE" | sed 's/^[* ]*//')
	help "Remote releases NOT merged into master:"
	if [ -z "$releases" ]; then
		info 'No release branch NOT merged exists.'
		echo
	else
		local release
		for release in $releases; do
			info "Release: $release"
			git show $release --pretty=medium | grep -v '^Merge: ' | head -n4
		done
	fi
}

function cmd_start {
	local release="$1"; require_arg 'release' "$release"
	local release_fullname="$TWGIT_PREFIX_RELEASE$release"
	
	#checks
	assert_valid_ref_name $release
	assert_clean_working_tree
	if [ $(has $release_fullname $(get_local_branches)) = '1' ]; then
		die "Local release '$release_fullname' already exists! Pick another name."
	fi
	
	processing "git fetch $TWGIT_ORIGIN..."
	git fetch $TWGIT_ORIGIN || die "Could not fetch '$TWGIT_ORIGIN'!"
	
	processing 'Check remote releases...'
	local is_remote_exists=$(has "$TWGIT_ORIGIN/$release_fullname" $(get_remote_branches))
	if [ $is_remote_exists = '1' ]; then
		processing "Remote release '$release_fullname' detected."
	fi	
	
	processing 'Get last tag...'
	local last_tag=$(get_last_tag)
	if [ -z "$last_tag" ]; then
		die 'No tag created!'
	fi
	#local short_last_tag=${last_tag:${#$TWGIT_PREFIX_TAG}}
	
	processing "git checkout -b $release_fullname $last_tag"
	git checkout -b $release_fullname $last_tag || die "Could not check out tag '$last_tag'!"
	
	local commit_msg=$(printf "$TWGIT_FIRST_COMMIT_MSG" "release" "$release_fullname")
	processing "git commit --allow-empty -am \"$commit_msg\""
	git commit --allow-empty -am "$commit_msg" || die "Could not make init commit!"
	
	local git_options=$([ $is_remote_exists = '0' ] && echo '--set-upstream' || echo '')
	processing "git push $git_options $TWGIT_ORIGIN $release_fullname"
	git push $git_options $TWGIT_ORIGIN $release_fullname || die "Could not push release '$release_fullname'!"
}

function cmd_finish {
	local release="$1"; require_arg 'release' "$release"
	local release_fullname="$TWGIT_PREFIX_RELEASE$release"
	
	local tag="$2"; require_arg 'tag' "$tag"
	local tag_fullname="$TWGIT_PREFIX_TAG$tag"
	
	assert_clean_working_tree
	
	processing "git fetch $TWGIT_ORIGIN..."
	git fetch $TWGIT_ORIGIN || die "Could not fetch '$TWGIT_ORIGIN'!"
	
	processing 'Check remote releases...'
	local is_release_exists=$(has "$TWGIT_ORIGIN/$release_fullname" $(get_remote_branches))
	if [ $is_release_exists = '0' ]; then
		die "Unknown '$release_fullname' remote release! Try: twgit release list"
	fi
	assert_branches_equal "$release_fullname" "$TWGIT_ORIGIN/$release_fullname"
	
	processing 'Check tags...'
	local is_tag_exixsts=$(has "$tag_fullname" $(get_all_tags))
	if [ $is_tag_exixsts = '1' ]; then
		die "Tag '$tag_fullname' already exists! Try: twgit tag list"
	fi
	
	processing "[git] git checkout $TWGIT_MASTER"
	git checkout $TWGIT_MASTER || die "Could not checkout '$TWGIT_ORIGIN'!"
	
	processing "[git] git merge --no-ff $TWGIT_ORIGIN/$TWGIT_MASTER"
	git merge --no-ff $TWGIT_ORIGIN/$TWGIT_MASTER || die "Could not merge '$TWGIT_ORIGIN/$TWGIT_MASTER' into '$TWGIT_MASTER'!"
	
	processing "[git] git merge --no-ff $release_fullname"
	git merge --no-ff $release_fullname || die "Could not merge '$release_fullname' into '$TWGIT_MASTER'!"
	
	processing "[git] git tag -a $tag_fullname -m "[by twgit] twgit release finish $release_fullname""
	git tag -a $tag_fullname -m "[by twgit] twgit release finish $release_fullname" || die "Could not tag '$TWGIT_MASTER'!"
	
	processing "[git] git push --tags $TWGIT_ORIGIN $TWGIT_MASTER"
	git push --tags $TWGIT_ORIGIN $TWGIT_MASTER || die "Could not push '$TWGIT_MASTER' on '$TWGIT_ORIGIN'!"
}

function cmd_remove {
	local release="$1"; require_arg 'release' "$release"
	local release_fullname="$TWGIT_PREFIX_RELEASE$release"
	
	assert_valid_ref_name $release
	
	processing "Check current branch..."	
	[ $(get_current_branch) = "$release_fullname" ] && die "Cannot delete the release '$release_fullname' which you are currently on!"
	
	processing "git fetch $TWGIT_ORIGIN..."
	git fetch $TWGIT_ORIGIN || die "Could not fetch '$TWGIT_ORIGIN'!"
	
	if [ $(has $release_fullname $(get_local_branches)) = '1' ]; then
		processing "git branch -D $release_fullname"
		git branch -D $release_fullname || die "Remove local release '$release_fullname' failed!"
	else
		processing "Local release '$release_fullname' not found."
	fi
	
	if [ $(has "$TWGIT_ORIGIN/$release_fullname" $(get_remote_branches)) = '1' ]; then
		processing "git push $TWGIT_ORIGIN :$release_fullname"
		git push $TWGIT_ORIGIN :$release_fullname
		if [ $? -ne 0 ]; then
			processing "Remove remote release '$TWGIT_ORIGIN/$release_fullname' failed! Maybe already deleted... so:"
			processing "git remote prune $TWGIT_ORIGIN"
			git remote prune $TWGIT_ORIGIN || die "Prune failed!"
		fi
	else
		die "Remote release '$TWGIT_ORIGIN/$release_fullname' not found!"
	fi	
}
