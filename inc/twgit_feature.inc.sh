#!/bin/bash

assert_git_repository
assert_php_curl

##
# Affiche l'aide de la commande tag.
#
function usage () {
	echo; help 'Usage:'
	help_detail 'twgit feature <action>'
	echo; help 'Available actions are:'
	help_detail '<b>committers <featurename></b>'
	help_detail '    List committers into the specified remote feature.'; echo
	help_detail '<b>list [-c|-F|-x]</b>'
	help_detail '    List remote features. Add <b>-F</b> to do not make fetch, <b>-c</b> to compact display'
	help_detail '    and <b>-x</b> (eXtremely compact) to CSV display.'; echo
	help_detail '<b>merge-into-release <featurename></b>'
	help_detail '    Try to merge specified feature into current release.'; echo
	help_detail '<b>migrate <oldfeaturefullname> <newfeaturename></b>'
	help_detail '    Migrate old branch to new process.'; echo
	help_detail '<b>remove <featurename></b>'
	help_detail '    Remove both local and remote specified feature branch.'; echo
	help_detail '<b>start <featurename> [-d]</b>'
	help_detail '    Create both a new local and remote feature, or fetch the remote feature,'
	help_detail '    or checkout the local feature. Add <b>-d</b> to delete beforehand local feature'
	help_detail '    if exists.'
	help_detail "    Prefix '$TWGIT_PREFIX_FEATURE' will be added to the specified <b><featurename></b>."; echo
	help_detail '<b>[help]</b>'
	help_detail '    Display this help.'; echo
}

##
# Action déclenchant l'affichage de l'aide.
#
function cmd_help () {
	usage
}

##
# Liste les personnes ayant committé sur la feature.
#
# @param string $1 nom court de la feature
#
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

##
# Liste les features et leur statut par rapport aux releases.
# Gère l'option '-F' permettant d'éviter le fetch.
# Gère l'option '-c' compactant l'affichage en masquant les détails de commit auteur et date.
# Gère l'option '-x' (eXtremely compact) retournant un affichage CVS.
#
function cmd_list () {
	process_options "$@"
	if isset_option 'x'; then
		process_fetch 'F' 1>/dev/null
	else
		process_fetch 'F'
	fi

	local features
	local prefix="$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE"
	features=$(git branch -r --merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
	if isset_option 'x'; then
		display_csv_branches "$features" "merged into stable"
	elif [ ! -z "$features" ]; then
		help "Remote features merged into '<b>$TWGIT_STABLE</b>' via releases:"
		warn 'They would not exists!'
		display_branches 'feature' "$features"; echo
	fi

	local release="$(get_current_release_in_progress)"
	if [ -z "$release" ]; then
		if ! isset_option 'x'; then
			help "Remote delivered features merged into release in progress:"
			info 'No such branch exists.'; echo
		fi
	else
		features_merged="$(get_merged_features $release)"
		features_in_progress="$(get_features merged_in_progress $release)"
		if isset_option 'x'; then
			display_csv_branches "$features_merged" "merged into release"
			display_csv_branches "$features_in_progress" "merged into release, then in progress"
		else
			help "Remote delivered features merged into release in progress '<b>$TWGIT_ORIGIN/$release</b>':"
			display_branches 'feature' "$features_merged"; echo
			help "Remote features in progress, previously merged into '<b>$TWGIT_ORIGIN/$release</b>':"
			display_branches 'feature' "$features_in_progress"; echo
		fi
	fi

	features="$(get_features free $release)"
	if isset_option 'x'; then
		display_csv_branches "$features" "free"
	else
		help "Remote free features:"
		display_branches 'feature' "$features"; echo
	fi

	if ! isset_option 'x'; then
		local dissident_branches="$(get_dissident_remote_branches)"
		if [ ! -z "$dissident_branches" ]; then
			warn "Following branches are out of process: $(displayQuotedEnum $dissident_branches)!"; echo
		fi
	fi
}

##
# Migre une branche de dév de l'ancien workflow dans le présent, tout en préservant l'historique.
# Typiquement : rmxxxx => feature-xxxx
#
# @param string $1 nom complet de la branche de dév à migrer
# @param string $2 nom court de la future feature (c.-à-d. sans le préfix 'feature-')
#
function cmd_migrate () {
	process_options "$@"
	require_parameter 'full_old_name'
	local oldfeature_fullname="$RETVAL"
	require_parameter 'short_new_name'
	local feature="$RETVAL"
	local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"

	assert_valid_ref_name $feature
	assert_clean_working_tree

	processing 'Check local features...'
	if has $feature_fullname $(get_local_branches); then
		die "Local branch '$feature_fullname' already exists!"
	fi

	process_fetch
	processing 'Check remote features...'
	if ! has "$TWGIT_ORIGIN/$oldfeature_fullname" $(get_remote_branches); then
		die "Remote branch '$TWGIT_ORIGIN/$oldfeature_fullname' does not exist!"
	elif has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches); then
		die "Remote feature '$feature_fullname' already exists!"
	fi

	echo -n $(question "Are you sure to migrate '$oldfeature_fullname' to '$feature_fullname'? Branch '$oldfeature_fullname' will be deleted. [Y/N] "); read answer
	[ "$answer" != "Y" ] && [ "$answer" != "y" ] && die 'Branch migration aborted!'

	processing "Migrate '<b>$oldfeature_fullname</b>' to '<b>$feature_fullname</b>'..."
	exec_git_command "git checkout --track -b $feature_fullname $TWGIT_ORIGIN/$oldfeature_fullname" "Could not check out feature '$TWGIT_ORIGIN/$oldfeature_fullname'!"
	remove_local_branch "$oldfeature_fullname"
	remove_remote_branch "$oldfeature_fullname"
	exec_git_command "git merge --no-ff $TWGIT_STABLE" "Could not merge stable into '$feature_fullname'!"
	process_push_branch "$feature_fullname"
}

##
# Crée une nouvelle feature à partir du dernier tag.
# Gère l'option '-d' supprimant préalablement la feature locale, afin de forcer le récréation de la branche.
#
# @param string $1 nom court de la nouvelle feature.
#
function cmd_start () {
	process_options "$@"
	require_parameter 'feature'
	local feature="$RETVAL"
	local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"

	assert_valid_ref_name $feature
	assert_clean_working_tree
	process_fetch

	if isset_option 'd'; then
		if has $feature_fullname $(get_local_branches); then
			assert_working_tree_is_not_on_delete_branch $feature_fullname
			remove_local_branch $feature_fullname
		fi
	else
		assert_new_local_branch $feature_fullname
	fi

	processing 'Check remote features...'
	if has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches); then
		processing "Remote feature '$feature_fullname' detected."
		exec_git_command "git checkout --track -b $feature_fullname $TWGIT_ORIGIN/$feature_fullname" "Could not check out feature '$TWGIT_ORIGIN/$feature_fullname'!"
	else
		assert_tag_exists
		local last_tag=$(get_last_tag)
		exec_git_command "git checkout -b $feature_fullname $last_tag" "Could not check out tag '$last_tag'!"
		process_first_commit 'feature' "$feature_fullname"
		process_push_branch $feature_fullname
	fi
	alert_old_branch $TWGIT_ORIGIN/$feature_fullname with-help
	echo
}

##
# Merge la feature spécifiée dans la release en cours.
#
# @param string $1 la feature à merger dans la release en cours
#
function cmd_merge-into-release () {
	process_options "$@"
	require_parameter 'feature'
	local feature="$RETVAL"
	local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"

	# Récupération de la release en cours :
	local release_fullname=$(get_current_release_in_progress)
	local release="${release_fullname:${#TWGIT_PREFIX_RELEASE}}"

	# Tests préliminaires :
	assert_clean_working_tree
	process_fetch
	processing 'Check remote release...'
	[ -z "$release" ] && die 'No release in progress!'
	processing 'Check remote feature...'
	if ! has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches); then
		die "Remote feature '$TWGIT_ORIGIN/$feature_fullname' not found!"
	fi

	# Merge :
	local cmds="twgit feature start $feature
git pull $TWGIT_ORIGIN $feature_fullname
twgit release start
git pull $TWGIT_ORIGIN $release_fullname
git merge --no-ff $feature_fullname
git push $TWGIT_ORIGIN $release_fullname"
	IFS="$(echo -e "\n\r")"
	local error=0
	local prefix
	for cmd in $cmds; do
		if [ "$error" -ne 0 ]; then
			help_detail "$cmd"
		else
			[ "${cmd:0:6}" = 'twgit ' ] && prefix='shell# ' || prefix="${TWGIT_GIT_COMMAND_PROMPT}"
			processing "$prefix$cmd"
			if ! eval $cmd; then
				error=1
				error "Merge '$feature_fullname' into '$release_fullname' aborted!"
				help 'Commands not executed:'
				help_detail "$cmd"
				if [ "${cmd:0:10}" = "git merge " ]; then
					help_detail "  - resolve conflicts"
					help_detail "  - git add..."
					help_detail "  - git commit..."
				fi
			fi
		fi
	done
	echo
	[ "$error" -eq 0 ] || exit 1
}

##
# Suppression de la feature spécifiée.
#
# @param string $1 nom court de la feature à supprimer
#
function cmd_remove () {
	process_options "$@"
	require_parameter 'feature'
	local feature="$RETVAL"
	remove_feature "$feature"
	echo
}
