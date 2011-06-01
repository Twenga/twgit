#!/bin/bash

assert_git_repository

##
# Affiche l'aide de la commande tag.
#
function usage () {
	echo; help 'Usage:'
	help_detail 'twgit hotfix <action>'
	echo; help 'Available actions are:'
	help_detail '<b>finish <hotfixname></b>'
	help_detail "    Merge specified hotfix branch into '$TWGIT_STABLE', create a new tag and push."; echo
	help_detail '<b>list</b>'
	help_detail '    List 5 last hotfixes. Add <b>-f</b> to do not make fetch.'; echo
	help_detail '<b>remove <hotfixname></b>'
	help_detail '    Remove both local and remote specified hotfix branch.'; echo
	help_detail '<b>start</b>'
	help_detail '    Create both a new local and remote hotfix, or fetch the remote hotfix.'
	help_detail '    Hotfix name will be: major.minor.(revision+1)'
	help_detail "    Prefix '$TWGIT_PREFIX_HOTFIX' will be added to the specified <hotfixname>."; echo
	help_detail '<b>[help]</b>'
	help_detail '    Display this help.'; echo
}

##
# Action déclenchant l'affichage de l'aide.
#
function cmd_help () {
	usage;
}

##
# Liste les derniers hotfixes.
# Gère l'option '-f' permettant d'éviter le fetch.
#
function cmd_list () {
	process_options "$@"
	process_fetch 'f'

	local n='5'
	local hotfixes=$(get_last_hotfixes $n)
	help "Remote last $n hotfixes:"
	display_branches 'Hotfix: ' "$hotfixes"
}

##
# Crée un nouveau hotfix à partir du dernier tag.
# Son nom est le dernier tag en incrémentant le numéro de révision : major.minor.(revision+1)
#
function cmd_start () {
	[ ! -z "$(get_hotfixes_in_progress)" ] && die "No more one hotfix is authorized at the same time! Try: twgit hotfix list"
	assert_tag_exists
	local last_tag=$(get_last_tag)
	local short_last_tag=${last_tag:${#TWGIT_PREFIX_TAG}}
	local hotfix=$(get_next_version 'revision' $short_last_tag)
	local hotfix_fullname="$TWGIT_PREFIX_HOTFIX$hotfix"

	assert_valid_ref_name $hotfix
	assert_clean_working_tree
	assert_new_local_branch $hotfix_fullname

	process_fetch

	processing 'Check remote hotfixes...'
	local is_remote_exists=$(has "$TWGIT_ORIGIN/$hotfix_fullname" $(get_remote_branches) && echo 1 || echo 0)
	if [ $is_remote_exists = '1' ]; then
		processing "Remote hotfix '$hotfix_fullname' detected."
	fi

	exec_git_command "git checkout -b $hotfix_fullname $last_tag" "Could not check out tag '$last_tag'!"

	process_first_commit 'hotfix' "$hotfix_fullname"
	process_push_branch $hotfix_fullname $is_remote_exists
}

##
# Supprime le hotfix spécifié.
#
# @param string $1 nom court du hotfix
#
function cmd_remove () {
	process_options "$@"
	require_parameter 'hotfix'
	local hotfix="$RETVAL"
	local hotfix_fullname="$TWGIT_PREFIX_HOTFIX$hotfix"

	assert_valid_ref_name $hotfix
	assert_clean_working_tree
	assert_working_tree_is_not_on_delete_branch $hotfix_fullname

	process_fetch
	remove_local_branch $hotfix_fullname
	remove_remote_branch $hotfix_fullname
}

##
# Merge le hotfix à la branche stable et crée un tag portant son nom.
#
# @param string $1 nom court du hotfix
#
function cmd_finish () {
	process_options "$@"
	require_parameter 'hotfix'
	local hotfix="$RETVAL"
	local hotfix_fullname="$TWGIT_PREFIX_HOTFIX$hotfix"

	local tag="$hotfix"
	local tag_fullname="$TWGIT_PREFIX_TAG$tag"

	assert_clean_working_tree
	process_fetch

	processing 'Check remote hotfix...'
	local is_hotfix_exists=$(has "$TWGIT_ORIGIN/$hotfix_fullname" $(get_remote_branches) && echo 1 || echo 0)
	[ $is_hotfix_exists = '0' ] && die "Unknown '$hotfix_fullname' remote hotfix! Try: twgit hotfix list"

	has $hotfix_fullname $(get_local_branches) && assert_branches_equal "$hotfix_fullname" "$TWGIT_ORIGIN/$hotfix_fullname"

	assert_valid_tag_name $tag_fullname
	processing 'Check tags...'
	local is_tag_exists=$(has "$tag_fullname" $(get_all_tags) && echo 1 || echo 0)
	[ $is_tag_exists = '1' ] && die "Tag '$tag_fullname' already exists! Try: twgit tag list"

	exec_git_command "git checkout $TWGIT_STABLE" "Could not checkout '$TWGIT_STABLE'!"
	exec_git_command "git merge --no-ff $TWGIT_ORIGIN/$TWGIT_STABLE" "Could not merge '$TWGIT_ORIGIN/$TWGIT_STABLE' into '$TWGIT_STABLE'!"
	exec_git_command "git merge --no-ff $hotfix_fullname" "Could not merge '$hotfix_fullname' into '$TWGIT_STABLE'!"

	processing "${TWGIT_GIT_COMMAND_PROMPT}git tag -a $tag_fullname -m \"${TWGIT_PREFIX_COMMIT_MSG}Hotfix finish: $hotfix_fullname\""
	git tag -a $tag_fullname -m "${TWGIT_PREFIX_COMMIT_MSG}Hotfix finish: $hotfix_fullname" || die "$error_msg"

	exec_git_command "git push --tags $TWGIT_ORIGIN $TWGIT_STABLE" "Could not push '$TWGIT_STABLE' on '$TWGIT_ORIGIN'!"

	# Suppression de la branche :
	cmd_remove $hotfix

	local current_release="$(get_current_release_in_progress)"
	[ ! -z "$current_release" ] && warn "Do not forget to merge '$tag_fullname' tag into '$current_release' release before close them!"
}

