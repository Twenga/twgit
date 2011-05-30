#!/bin/bash

assert_git_repository

function usage () {
	echo; help 'Usage:'
	help_detail 'twgit feature <action>'
	echo; help 'Available actions are:'
	help_detail '<b>committers <featurename></b>'
	help_detail '    List committers into the specified remote feature.'; echo
	help_detail '<b>list</b>'
	help_detail '    List remote features. Add <b>-f</b> to do not make fetch.'; echo
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
	process_fetch 'f'

	local features=$(git branch -r --merged $TWGIT_ORIGIN/HEAD | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
	help "Remote features merged into master via releases:"
	if [ -z "$features" ]; then
		info 'No feature branch exists.'; echo
	else
		display_branches 'Feature: ' "$features"
	fi

	local releases=$(git branch -r --no-merged $TWGIT_ORIGIN/HEAD | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_RELEASE" | sed 's/^[* ]*//')
	local release="$(echo $releases | cut -d' ' -f1)"
	if [ -z "$releases" ]; then
		help "Remote features merged into releases in progress:"
		info 'No release branch in progress.'; echo
	else
		[[ $(echo $releases | wc -w) > 1 ]] && warn "More than one release in propress detected! Only '$release' will be treated here."
		help "Remote features merged into release in progress '$release':"
		local features=$(git branch -r --merged $release | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
		if [ -z "$features" ]; then
			info 'No feature branch exists.'; echo
		else
			display_branches 'Feature: ' "$features"
		fi
	fi

	local features=$(git branch -r | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
	help "Remote features in progress not merged into releases:"
	if [ -z "$features" ]; then
		info 'No feature branch exists.'; echo
	else
		display_branches 'Feature: ' "$features"
	fi

	help "Remote features in progress merged into releases in the past:"
	local features_merged=$(git branch -r --merged origin/release-test | grep "origin/feature-" | sed 's/^[* ]*//')
	local fs=$(git branch -r | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
	local head_rev=$(git rev-parse origin/HEAD)
	local release_rev=$(git rev-parse origin/release-test)
	for f in $fs; do
		f_rev=$(git rev-parse $f)
		merge_base=$(git merge-base $release_rev $f_rev)
		master_merge_base=$(git merge-base $release_rev $head_rev)
		echo "f=$f"
		echo "f_rev=$f_rev"
		echo "release_rev=$release_rev"
		echo "merge_base=$merge_base"
		echo "master_merge_base=$master_merge_base"
		[ "$merge_base" = "$f_rev" ] && echo "MERGED" || (\
		[ "$merge_base" != "$master_merge_base" ] && echo "MERGED AND IN PROGRESS" || echo "OUT" )
		echo
	done

	echo "merged>>>$(get_features merged $release)<"
	echo "merged in progress>>>$(get_features merged_in_progress $release)<"
	echo "free>>>$(get_features free $release)<"
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

	exec_git_command "git checkout -b $feature_fullname $last_tag" "Could not check out tag '$last_tag'!"

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
