#!/bin/bash

assert_git_repository

##
# Affiche l'aide de la commande tag.
#
function usage () {
	echo; help 'Usage:'
	help_detail 'twgit hotfix <action>'
	echo; help 'Available actions are:'
	help_detail '<b>finish [-I]</b>'
	help_detail "    Merge current hotfix branch into '$TWGIT_STABLE', create a new tag and push."
	help_detail '    Add <b>-I</b> to run in non-interactive mode (always say yes).'; echo
	help_detail '<b>list [-F]</b>'
	help_detail '    List current hotfix. Add <b>-F</b> to do not make fetch.'; echo
	help_detail '<b>remove <hotfixname></b>'
	help_detail '    Remove both local and remote specified hotfix branch.'; echo
	help_detail '<b>start</b>'
	help_detail '    Create both a new local and remote hotfix, or fetch the remote hotfix,'
	help_detail '    or checkout the local hotfix.'
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
# Gère l'option '-F' permettant d'éviter le fetch.
#
function cmd_list () {
	process_options "$@"
	process_fetch 'F'

	local hotfixes=$(get_last_hotfixes 1)
	help "Remote current hotfix:"
	display_branches 'hotfix' "$hotfixes"; echo
}

##
# Crée un nouveau hotfix à partir du dernier tag.
# Son nom est le dernier tag en incrémentant le numéro de révision : major.minor.(revision+1)
#
function cmd_start () {
	assert_clean_working_tree
	process_fetch

	processing 'Check remote hotfixes...'
	local remote_hotfix="$(get_hotfixes_in_progress)"
	local hotfix
	if [ -z "$remote_hotfix" ]; then
		assert_tag_exists
		local last_tag=$(get_last_tag)
		hotfix=$(get_next_version 'revision')
		local hotfix_fullname="$TWGIT_PREFIX_HOTFIX$hotfix"
		exec_git_command "git checkout -b $hotfix_fullname $last_tag" "Could not check out tag '$last_tag'!"
		process_first_commit 'hotfix' "$hotfix_fullname"
		process_push_branch $hotfix_fullname
	else
		local prefix="$TWGIT_ORIGIN/$TWGIT_PREFIX_HOTFIX"
		hotfix="${remote_hotfix:${#prefix}}"
		processing "Remote hotfix '$TWGIT_PREFIX_HOTFIX$hotfix' detected."
		assert_valid_ref_name $hotfix
		local hotfix_fullname="$TWGIT_PREFIX_HOTFIX$hotfix"
		assert_new_local_branch $hotfix_fullname
		exec_git_command "git checkout --track -b $hotfix_fullname $remote_hotfix" "Could not check out hotfix '$remote_hotfix'!"
	fi
	echo
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
	echo
}

##
# Merge le hotfix à la branche stable et crée un tag portant son nom.
# Gère l'option '-I' permettant de répondre automatiquement (mode non interactif) oui à la demande de pull.
#
# @param string $1 nom court du hotfix
#
function cmd_finish () {
	assert_clean_working_tree
	process_fetch

	processing 'Check remote hotfix...'
	local remote_hotfix="$(get_hotfixes_in_progress)"
	[ -z "$remote_hotfix" ] && die 'No hotfix in progress!'
	local prefix="$TWGIT_ORIGIN/$TWGIT_PREFIX_HOTFIX"
	hotfix="${remote_hotfix:${#prefix}}"
	local hotfix_fullname="$TWGIT_PREFIX_HOTFIX$hotfix"
	processing "Remote hotfix '$hotfix_fullname' detected."

	processing "Check local branch '$hotfix_fullname'..."
	if has $hotfix_fullname $(get_local_branches); then
		assert_branches_equal "$hotfix_fullname" "$TWGIT_ORIGIN/$hotfix_fullname"
	else
		exec_git_command "git checkout --track -b $hotfix_fullname $TWGIT_ORIGIN/$hotfix_fullname" "Could not check out hotfix '$TWGIT_ORIGIN/$hotfix_fullname'!"
	fi

	local tag="$hotfix"
	local tag_fullname="$TWGIT_PREFIX_TAG$tag"
	assert_valid_tag_name $tag_fullname
	processing "Check whether tag '$tag_fullname' already exists..."
	has "$tag_fullname" $(get_all_tags) && die "Tag '$tag_fullname' already exists! Try: twgit tag list"

	exec_git_command "git checkout $TWGIT_STABLE" "Could not checkout '$TWGIT_STABLE'!"
	exec_git_command "git merge $TWGIT_ORIGIN/$TWGIT_STABLE" "Could not merge '$TWGIT_ORIGIN/$TWGIT_STABLE' into '$TWGIT_STABLE'!"
	exec_git_command "git merge --no-ff $hotfix_fullname" "Could not merge '$hotfix_fullname' into '$TWGIT_STABLE'!"

	processing "${TWGIT_GIT_COMMAND_PROMPT}git tag -a $tag_fullname -m \"${TWGIT_PREFIX_COMMIT_MSG}Hotfix finish: $hotfix_fullname\""
	git tag -a $tag_fullname -m "${TWGIT_PREFIX_COMMIT_MSG}Hotfix finish: $hotfix_fullname" || die "$error_msg"

	exec_git_command "git push --tags $TWGIT_ORIGIN $TWGIT_STABLE" "Could not push '$TWGIT_STABLE' on '$TWGIT_ORIGIN'!"

	# Suppression de la branche :
	cmd_remove $hotfix

	local current_release="$(get_current_release_in_progress)"
	[ ! -z "$current_release" ] && warn "Do not forget to merge '$tag_fullname' tag into '$current_release' release before close it! Try on release: git merge --no-ff $tag_fullname"
	echo
}

