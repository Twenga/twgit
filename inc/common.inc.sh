#!/bin/bash

. $TWGIT_INC_DIR/options_handler.inc.sh
. $TWGIT_INC_DIR/ui.inc.sh



#--------------------------------------------------------------------
# Functions "Get"
#--------------------------------------------------------------------

##
# Affiche les $1 derniers hotfixes (nom complet), à raison d'un par ligne.
#
# @param int $1 nombre des derniers hotfixes à afficher
#
function get_last_hotfixes () {
	git branch -r --no-color | grep $TWGIT_ORIGIN/$TWGIT_PREFIX_HOTFIX | sed 's/^[* ] //' | sort -n | tail -n $1
}

##
# Affiche les branches locales (nom complet), à raison d'une par ligne.
#
function get_local_branches () {
	git branch --no-color | sed 's/^[* ] //'
}

##
# Affiche la liste locale des branches distantes (nom complet), à raison d'une par ligne.
#
function get_remote_branches () {
	git branch -r --no-color | sed 's/^[* ] //'
}

##
# Affiche la liste des branches distantes qui ne sont pas catégorisables dans le process.
#
function get_dissident_remote_branches () {
	git branch -r --no-color | sed 's/^[* ] //' \
		| grep -vP "^$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" \
		| grep -vP "^$TWGIT_ORIGIN/$TWGIT_PREFIX_RELEASE" \
		| grep -vP "^$TWGIT_ORIGIN/$TWGIT_PREFIX_HOTFIX" \
		| grep -vP "^$TWGIT_ORIGIN/$TWGIT_PREFIX_DEMO" \
		| grep -vP "^$TWGIT_ORIGIN/HEAD" \
		| grep -vP "^$TWGIT_ORIGIN/master" \
		| grep -vP "^$TWGIT_ORIGIN/$TWGIT_STABLE"
}

##
# Affiche le nom complet des releases non encore mergées à $TWGIT_ORIGIN/$TWGIT_STABLE, à raison d'une par ligne.
#
function get_releases_in_progress () {
	git branch -r --no-merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_RELEASE" | sed 's/^[* ]*//'
}

##
# Affiche le nom complet des releases non encore mergées à $TWGIT_ORIGIN/$TWGIT_STABLE, à raison d'une par ligne.
#
function get_hotfixes_in_progress () {
	git branch -r --no-merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_HOTFIX" | sed 's/^[* ]*//'
}

##
# Affiche la release courante (nom complet + origin), c.-à-d. celle normallement unique à ne pas avoir été encore mergée à $TWGIT_ORIGIN/$TWGIT_STABLE.
# Chaîne vide sinon.
#
function get_current_release_in_progress () {
	local releases="$(get_releases_in_progress)"
	local release="$(echo $releases | tr '\n' ' ' | cut -d' ' -f1)"
	[[ $(echo $releases | wc -w) > 1 ]] && die "More than one release in propress detected: $(echo $releases | sed 's/ /, /g')! Only '$release' will be treated here."
	echo $release
}

##
# Affiche la liste locale des features distantes (nom complet) mergées à la release $1, sur une seule ligne séparées par des espaces.
#
# @param string $1 nom complet d'une release
#
function get_merged_features () {
	local release="$1"
	local features="$(git branch -r --merged $release | grep $TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g')"
	local features_v2="$(get_features merged $release)"
	[ "$features" != "$features_v2" ] && die "Inconsistent result about merged features: '$features' != '$features_v2'!"
	echo $features
}

##
# Affiche la liste des features (nom complet) de relation de type $1 avec la release $2, sur une seule ligne séparées par des espaces.
#
# @param string $1 Type de relation avec la release $2 :
#    - 'merged' pour lister les features mergées dans la release $2 et restées telle quelle depuis.
#    - 'merged_in_progress' pour lister les features mergées dans la release $2 et dont le développement à continué.
#    - 'free' pour lister celles n'ayant aucun rapport avec la release $2
# @param string $2 nom complet d'une release
#
function get_features () {
	local feature_type="$1"
	local release="$2"

	if [ -z "$release" ]; then
		if [ "$feature_type" = 'merged' ] || [ "$feature_type" = 'merged_in_progress' ]; then
			echo ''
		elif [ "$feature_type" = 'free' ]; then
			git branch -r --no-merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g'
		fi
	else
		local return_features=''
		#local features_merged=$(git branch -r --merged $release | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
		local features=$(git branch -r | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
		local head_rev=$(git rev-parse $TWGIT_ORIGIN/$TWGIT_STABLE)
		local release_rev=$(git rev-parse $release)

		local f_rev release_merge_base stable_merge_base
		for f in $features; do
			f_rev=$(git rev-parse $f)
			release_merge_base=$(git merge-base $release_rev $f_rev)
			stable_merge_base=$(git merge-base $release_merge_base $head_rev)

			if [ "$release_merge_base" = "$f_rev" ]; then
				[ "$feature_type" = 'merged' ] && return_features="$return_features $f"
			elif [ "$release_merge_base" != "$stable_merge_base" ]; then
				[ "$feature_type" = 'merged_in_progress' ] && return_features="$return_features $f"
			elif [ "$feature_type" = 'free' ]; then
				return_features="$return_features $f"
			fi
		done
		echo ${return_features:1}
	fi
}

##
# Affiche le nom complet de la branche courante, chaîne vide sinon.
#
function get_current_branch () {
	git branch --no-color | grep '^\* ' | grep -v 'no branch' | sed 's/^* //g'
}

##
# Affiche la liste des tags (nom complet) triés par ordre croissant, à raison d'un par ligne.
#
# @param int $1 si renseigné alors limite la liste aux $1 derniers tags
#
function get_all_tags () {
	local n="$1"
	if [ -z "$n" ]; then
		git tag | sort -n
	else
		git tag | sort -n | tail -n $n
	fi
}

##
# Affiche le nom complet du tag le plus récent.
#
function get_last_tag () {
	git tag | sort -rn | head -n 1
}

##
# Affiche le nom complet des tags réalisés depuis la création de la branche $1 (via hotfixes ou releases), et qui n'y sont pas mergés.
# Sur une seule ligne, séparés par des espaces.
#
# @param string $1 nom complet de la branche, locale ou distante
#
function get_tags_not_merged_into_branch () {
	local release_rev=$(git rev-parse $1)
	local tag_rev merge_base
	local tags=''
	for t in $(get_all_tags); do
		tag_rev=$(git rev-list $t | head -n 1)
		merge_base=$(git merge-base $release_rev $tag_rev)
		[ "$tag_rev" != "$merge_base" ] && tags="$tags $t"
	done
	echo ${tags:1}
}

##
# Affiche le prochain numéro de version suivant le type d'évolution spécifié.
# Une version est du type [major].[minor].[revision].
#
# @param string $1 type d'évolution : 'major', 'minor' ou 'revision'
#
function get_next_version () {
	local change_type="$1"
	local last_tag=$(get_last_tag)
	local current_version=${last_tag:${#TWGIT_PREFIX_TAG}}

	local major=$(echo $current_version | cut -d. -f1)
	local minor=$(echo $current_version | cut -d. -f2)
	local revision=$(echo $current_version | cut -d. -f3)

	case "$change_type" in
		major) let major++; minor=0; revision=0 ;;
		minor) let minor++; revision=0 ;;
		revision) let revision++ ;;
		*) die "Invalid version change type: '$change_type'!" ;;
	esac
	echo "$major.$minor.$revision"
}

# git shortlog -nse ne comptabilise que les commits...
function get_rank_contributors () {
	local branch="$1" author state='pre_author'
	declare -A lines

	local tmpfile=$(tempfile)
	git log -M -C -p --no-color "$branch" > "$tmpfile"
	while read line; do
		if ([ "$state" = 'pre_author' ] || [ "$state" = 'post_author' ]) && [ "${line:0:8}" = 'Author: ' ]; then
			author=$(echo "${line:8}" | sed 's/.*<//' | sed 's/>.*//')
			if [ "$author" != "fs3@twenga.com" ]; then
				state='post_author'
				let lines[$author]=0
			fi
		fi
		if [ "$state" = 'post_author' ] && [ "${line:0:3}" = '+++' ]; then
			state='in_diff'
		fi
		if [ "$state" = 'in_diff' ] && ([ "${line:0:1}" = '+' ] || [ "${line:0:1}" = '-' ]); then
			let lines[$author]++
		fi
		if [ "$state" = 'in_diff' ] && [ "${line:0:6}" = 'commit' ]; then
			state='pre_author'
		fi
	done < "$tmpfile"
	rm -f "$tmpfile"
	# echo ">>>${#lines[@]}"
	echo "${!lines[@]}"
	# echo ">>>${lines[@]}"

	# sort -t: -k 3n /etc/passwd | more
	# Sort passwd file by 3rd field.
}

##
# Affiche le sujet d'un ticket Redmine, sans aucune coloration.
# Le premier appel sollicite ws_redmine.inc.php qui lui-même exploite un WS Redmine,
# les suivants bénéficieront du fichier de cache $TWGIT_REDMINE_PATH.
#
# @param int $1 numéro de ticket Redmine
#
function getRedmineSubject () {
	local redmine="$1"
	local subject

	[ ! -s "$TWGIT_REDMINE_PATH" ] && touch "$TWGIT_REDMINE_PATH"

	subject="$(cat "$TWGIT_REDMINE_PATH" | grep -E "^$redmine;" | head -n 1 | sed 's/^.*;//')"
	if [ -z "$subject" ]; then
		subject="$(php -q ~/twgit/inc/ws_redmine.inc.php $redmine subject 2>/dev/null || echo)"
		[ ! -z "$subject" ] && echo "$redmine;$subject" >> "$TWGIT_REDMINE_PATH"
	fi

	echo $subject
}



#--------------------------------------------------------------------
# Assertions
#--------------------------------------------------------------------

##
# S'assure que le client git a bien ses globales user.name et user.email de configurées.
#
function assert_git_configured () {
	if ! git config --global user.name 1>/dev/null; then
		die "Unknown user.name! Please, do: git config --global user.name 'Firstname Lastname'"
	elif ! git config --global user.email 1>/dev/null; then
		die "Unknown user.email! Please, do: git config --global user.email 'firstname.lastname@twenga.com'"
	fi
}

##
# S'assure que l'utilisateur se trouve dans un dépôt git et que celui-ci possède une branche stable.
#
function assert_git_repository () {
	local errormsg=$(git rev-parse --git-dir 2>&1 1>/dev/null)
	[ ! -z "$errormsg" ] && die "[Git error msg] $errormsg"

	assert_recent_git_version "$TWGIT_GIT_MIN_VERSION"

	local stable="$TWGIT_ORIGIN/$TWGIT_STABLE"
	if ! has $stable $(get_remote_branches); then
		process_fetch
		if ! has $stable $(get_remote_branches); then
			die "Remote stable branch not found: '$TWGIT_ORIGIN/$TWGIT_STABLE'!"
		fi
	fi
}

##
# S'assure que la lib PHP cURL est présente, afin de permettre la récupération des sujets des tickets Redmine.
#
function assert_php_curl () {
	if ! php --ri curl 2>/dev/null 1>&2; then
		warn 'PHP lib cURL not installed: Redmine subjects will not be fetched.'
		processing 'Try: sudo apt-get install php5-curl'
	fi
}

##
# S'assure que les 2 branches spécifiées sont au même niveau.
# Gère l'option '-I' permettant de répondre automatiquement (mode non interactif) oui à la demande de pull.
#
# @param string $1 nom complet d'une branche locale
# @param string $2 nom complet d'une branche distante
#
function assert_branches_equal () {
	processing "Compare branches '$1' with '$2'..."
	if ! has $1 $(get_local_branches); then
		die "Local branch '$1' does not exist and is required!"
	elif ! has $2 $(get_remote_branches); then
		die "Remote branch '$2' does not exist and is required!"
	fi

	compare_branches "$1" "$2"
	local status=$?
	if [ $status -gt 0 ]; then
		warn "Branches '$1' and '$2' have diverged."
		if [ $status -eq 1 ]; then
			warn "And local branch '$1' may be fast-forwarded!"
			if ! isset_option 'I'; then
				echo -n $(question "Pull '$1'? [Y/N] "); read answer
				[ "$answer" != "Y" ] && [ "$answer" != "y" ] && die "Pull aborted! You must make a 'git pull $TWGIT_ORIGIN $1' to continue."
			fi
			exec_git_command "git checkout $1" "Checkout '$1' failed!"
			exec_git_command "git merge $2" "Update '$1' failed!"
		elif [ $status -eq 2 ]; then
			# Warn here (not die), since there is no harm in being ahead:
			warn "And local branch '$1' is ahead of '$2'."
		else
			die "Branches need merging first!"
		fi
	fi
}

##
# S'assure que la branche spécifiée n'existe pas déjà en local, sinon effectue un checkout dessus,
# puis indique la fraîcheur de la branche locale vis-à-vis de la distante,
# puis affiche un warning si des tags ne sont pas présents dans la branche spécifiée, avant exit.
# Une erreur est affichée si la branche distante n'existe pas quand la locale existe.
#
# @param string $1 nom complet d'une branche potentiellement locale
#
function assert_new_local_branch () {
	local branch="$1"
	processing 'Check local branches...'
	if has $branch $(get_local_branches); then
		processing "Local branch '$branch' already exists!"
		if ! has "$TWGIT_ORIGIN/$branch" $(get_remote_branches); then
			error "Remote feature '$TWGIT_ORIGIN/$branch' not found while local one exists!"
			help 'Perhaps:'
			help_detail "- check the name of your branch"
			help_detail "- delete this out of process local branch: git branch -D $branch"
			help_detail "- or force renewal if feature: twgit feature start -d xxxx"
		else
			exec_git_command "git checkout $branch" "Could not checkout '$branch'!"

			# Informe de la fraîcheur de la branche :
			compare_branches "$branch" "$TWGIT_ORIGIN/$branch"
			local status=$?
			if [ $status -eq 0 ]; then
				help "Local branch '$branch' up-to-date."
			elif [ $status -eq 1 ]; then
				help "If need be: git merge $TWGIT_ORIGIN/$branch"
			elif [ $status -eq 2 ]; then
				help "If need be: git push $TWGIT_ORIGIN $branch"
			else
				warn "Branches '$branch' and '$TWGIT_ORIGIN/$branch' have diverged!"
			fi

			alert_old_branch $TWGIT_ORIGIN/$branch
		fi
		echo
		exit 0
	fi
}

##
# S'assure que le dépôt git courant est dans le status 'working directory clean'.
#
function assert_clean_working_tree () {
	processing 'Check clean working tree...'
	if [ `git status --porcelain --ignore-submodules=all | wc -l` -ne 0 ]; then
		error 'Untracked files or changes to be committed in your working tree!'
		exec_git_command 'git status' 'Git status failed!'
		exit 1
	fi
}

##
# S'assure que la référence fournie est un nom syntaxiquement correct de branche potentielle.
#
# @param string $1 référence de branche
#
function assert_valid_ref_name () {
	processing 'Check valid ref name...'
	git check-ref-format --branch "$1" 1>/dev/null 2>&1
	if [ $? -ne 0 ]; then
		die "'$1' is not a valid reference name!"
	elif  echo "$1" | grep -q ' '; then
		die "'$1' is not a valid reference name: whitespaces not allowed!"
	fi

	echo $1 | grep -vP "^$TWGIT_PREFIX_FEATURE" \
		| grep -vP "^$TWGIT_PREFIX_RELEASE" \
		| grep -vP "^$TWGIT_PREFIX_HOTFIX" \
		| grep -vP "^$TWGIT_PREFIX_DEMO" 1>/dev/null
	if [ $? -ne 0 ]; then
		die 'Unauthorized reference prefix! Pick another name.'
	fi
}

##
# S'assure que la référence fournie est un nom syntaxiquement correct de tag potentiel.
#
# @param string $1 référence de branche
#
function assert_valid_tag_name () {
	local tag="$1"
	assert_valid_ref_name "$tag"
	processing 'Check valid tag name...'
	$(echo "$tag" | grep -qP '^'$TWGIT_PREFIX_TAG'[0-9]+\.[0-9]+\.[0-9]+$') || die "Unauthorized tag name: '$tag'!"
}

##
# S'assure que l'on ne tente pas de supprimer une branche sur laquelle on se trouve (checkout),
# auquel cas on checkout sur $TWGIT_STABLE.
#
# @param string $1 nom complet de la branche locale en instance de suppression
#
function assert_working_tree_is_not_on_delete_branch () {
	local branch="$1"
	processing "Check current branch..."
	if [ $(get_current_branch) = "$branch" ]; then
		processing "Cannot delete the branch '$branch' which you are currently on! So:"
		exec_git_command "git checkout $TWGIT_STABLE" "Could not checkout '$TWGIT_STABLE'!"
	fi
}

##
# S'assure qu'au moins un tag existe.
#
function assert_tag_exists () {
	processing 'Get last tag...'
	local last_tag="$(get_last_tag)"
	[ -z "$last_tag" ] && die 'No tag exists!' || echo "Last tag: $last_tag"
}

##
# S'assure que l'outil Git est au moins dans la version $1.
#
# @param string $1 version minimale requise, au format '1.2.3' ou '1.2.3.4'
#
function assert_recent_git_version () {
	local needed=$(echo "$1" | awk -F. '{ printf("%d%02d%02d%02d\n", $1,$2,$3,$4); }')
	local current=$(git --version | sed 's/[^0-9.]//g' | awk -F. '{ printf("%d%02d%02d%02d\n", $1,$2,$3,$4); }')
	if [ $current -lt $needed ]; then
		error "Please update git! Current: $(git --version | sed 's/[^0-9.]//g'). Need $1 or newer."
		help 'Try:'
		help_detail 'sudo apt-add-repository ppa:git-core/ppa'
		help_detail 'sudo apt-get update'
		help_detail 'sudo apt-get install git'
		echo
		exit
	fi
}



#--------------------------------------------------------------------
# Traitements
#--------------------------------------------------------------------

##
# Effectue un fetch avec prise en compte des éventuelles suppressions de branches.
#
function process_fetch () {
	local option="$1"
	if [ -z "$option" ] || ! isset_option "$option"; then
		exec_git_command "git fetch --prune $TWGIT_ORIGIN" "Could not fetch '$TWGIT_ORIGIN'!"
		[ ! -z "$option" ] && echo
	fi
}

##
# Réalise un commit "blanc" permettant de dégager la référence de la branche courante de celle dont elle est issue.
# Dit autrement, la première ne sera plus un ancêtre de la seconde.
#
# @param string $1 titre à inclure dans le message de commit
# @param string $2 nom complet de la branche à décaler
# @see $TWGIT_FIRST_COMMIT_MSG
#
function process_first_commit () {
	local commit_msg=$(printf "$TWGIT_FIRST_COMMIT_MSG" "$1" "$2")
	processing "${TWGIT_GIT_COMMAND_PROMPT}git commit --allow-empty -m \"$commit_msg\""
	git commit --allow-empty -m "$commit_msg" || die 'Could not make initial commit!'
}

##
# Réalise un push de la branche locale spécifiée sur $TWGIT_ORIGIN.
#
# @param string $1 nom complet de la branche locale à pousser
#
function process_push_branch () {
	local branch="$1"
	exec_git_command "git push --set-upstream $TWGIT_ORIGIN $branch" "Could not push branch '$branch'!"
}

##
# Exécute la commande git spécifiée, affiche un message utilisateur et est à l'affût d'une éventuelle erreur d'exécution.
# NB : ne pas utiliser si des quotes sont nécessaires pour délimiter des paramètres de la commande...
# http://mywiki.wooledge.org/BashFAQ/050
#
# @param string $1 commande à exécuter
# @param string $2 message d'erreur pour le cas où...
#
function exec_git_command () {
	local cmd="$1"
	local error_msg="$2"
	processing "$TWGIT_GIT_COMMAND_PROMPT$cmd"
	$cmd || die "$error_msg"
}

##
# Supprime la branche locale spécifiée.
#
# @param string $1 nom complet de la branche locale
#
function remove_local_branch () {
	local branch="$1"
	if has $branch $(get_local_branches); then
		exec_git_command "git branch -D $branch" "Remove local branch '$branch' failed!"
	else
		processing "Local branch '$branch' not found."
	fi
}

##
# Supprime la branche distante spécifiée.
#
# @param string $1 nom de la branche distante sans le '$TWGIT_ORIGIN/'
#
function remove_remote_branch () {
	local branch="$1"
	if has "$TWGIT_ORIGIN/$branch" $(get_remote_branches); then
		exec_git_command "git push $TWGIT_ORIGIN :$branch" "Delete remote branch '$TWGIT_ORIGIN/$branch' failed!"
		if [ $? -ne 0 ]; then
			processing "Remove remote branch '$TWGIT_ORIGIN/$branch' failed! Maybe already deleted... so:"
			exec_git_command "git remote prune $TWGIT_ORIGIN" "Prune failed!"
		fi
	else
		die "Remote branch '$TWGIT_ORIGIN/$branch' not found!"
	fi
}

##
# Supprime la branche locale et distante de la feature spécifiée.
#
# @param string $1 nom court de la feature
#
function remove_feature () {
	local feature="$1"
	local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"

	assert_valid_ref_name $feature
	assert_clean_working_tree
	assert_working_tree_is_not_on_delete_branch $feature_fullname

	process_fetch
	remove_local_branch $feature_fullname
	remove_remote_branch $feature_fullname
}



#--------------------------------------------------------------------
# Autres fonctions...
#--------------------------------------------------------------------

##
# Echappe les caractères '.+$*' d'une chaîne.
#
# @param string $1 chaîne à échapper
#
function escape () {
	echo "$1" | sed 's/\([\.\+\$\*]\)/\\\1/g'
}

##
# Retourne 0 si la chaîne $1 est présente dans la concaténation du reste des paramètres, 1 sinon.
#
# @param string $1 chaîne à rechercher
# @param string $2-n chaînes dans lesquelles rechercher
# @return int 0 si la chaîne $1 est présente dans la concaténation du reste des paramètres, 1 sinon.
#
function has () {
	local item=$1; shift
	echo " $@ " | grep -q " $(escape $item) "
}

##
# Tests whether branches and their "origin" counterparts have diverged and need
# merging first. It returns error codes to provide more detail, like so:
#
# @return int
#    0    Branch heads point to the same commit
#    1    First given branch needs fast-forwarding
#    2    Second given branch needs fast-forwarding
#    3    Branch needs a real merge
#    4    There is no merge base, i.e. the branches have no common ancestors
#
# @author http://github.com/nvie/gitflow
#
function compare_branches () {
	local commit1=$(git rev-parse "$1")
	local commit2=$(git rev-parse "$2")
	if [ "$commit1" != "$commit2" ]; then
		local base=$(git merge-base "$commit1" "$commit2")
		if [ $? -ne 0 ]; then
			return 4
		elif [ "$commit1" = "$base" ]; then
			return 1
		elif [ "$commit2" = "$base" ]; then
			return 2
		else
			return 3
		fi
	else
		return 0
	fi
}

##
# Affiche une ligne CSV pour chacune des branches fournies.
# Exemple :
#    7278;feature-7278;merged into release;"Mail d\'alerte en cas d\'insertion KO dans Sugar"
#
# @param string $1 liste des branches à présenter, à raison d'une par ligne, au format 'origin/xxx'
# @param string $2 information de sous-type de branche
#
function display_csv_branches () {
	local branches="$1"
	local subtype="$2"
	local repo_prefix="$TWGIT_ORIGIN/"
	local prefix="$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE"

	local subject
	local short_name
	for branch in $branches; do
		short_name="${branch:${#prefix}}"
		subject="$(getRedmineSubject "$short_name")"
		echo "${branch:${#repo_prefix}};$short_name;$subtype;$(convertList2CSV "$subject")"
	done
}

##
# Affiche un court paragraphe descriptif pour chacune des branches fournies.
# Exemple :
#    [title]: origin/release-three
#    commit 9723329ce24daf342fdd04e8de4d58966dbf2609
#    Author: Geoffroy Aubry <geoffroy.aubry@twenga.com>
#    Date:   Wed May 25 18:58:05 2011 +0200
#
# @param string $1 type type de branches affichées, parmi {'feature', 'release', 'hotfix'}
# @param string $2 liste des branches à présenter, à raison d'une par ligne, au format 'origin/xxx'
#
function display_branches () {
	local type="$1"
	local branches="$2"
	local -A titles=(
		[feature]='Feature: '
		[release]='Release: '
		[hotfix]='Hotfix: '
	)

	if [ -z "$branches" ]; then
		info 'No such branch exists.';
	else
		local prefix="$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE"
		local add_empty_line=0
		for branch in $branches; do
			if ! isset_option 'c'; then
				[ "$add_empty_line" = "0" ] && add_empty_line=1 || echo
			fi
			echo -n $(info "${titles[$type]}$branch ")

			[ "$type" = "feature" ] && displayRedmineSubject "${branch:${#prefix}}" || echo

			alert_old_branch "$branch"

			# Afficher les informations de commit :
			! isset_option 'c' && git show $branch --pretty=medium | grep -v '^Merge: ' | head -n 3
		done
	fi
}

##
# Affiche un warning si des tags ne sont pas présents dans la branche spécifiée.
#
# @param string $1 nom complet de la branche, locale ou distante
#
function alert_old_branch () {
	local tags_not_merged="$(get_tags_not_merged_into_branch "$1")"
	[ ! -z "$tags_not_merged" ] && \
		warn "Following tags has not yet been merged into this branch: $(displayInterval "$tags_not_merged")"
}

##
# Affiche un interval "a to z" à partir du premier et du dernier élément de la liste fournie.
#
# @param string $1 liste de valeurs séparées par des espaces
#
function displayInterval () {
	local -a list=($@)
	local nb_items="${#list[@]}"
	local first_item="${list[0]}"
	local last_item="${list[$((nb_items-1))]}"

	echo -n "'<b>$first_item</b>'"
	[ "$nb_items" -gt 1 ] && echo " to '<b>$last_item</b>'" || echo
}

##
# Affiche la liste de valeurs sur une seule ligne, séparées par des virgules et chaque valeur entre simples quotes.
#
# @param string $@ liste de valeurs sur une ou plusieurs lignes, séparées par des espaces ou des sauts de ligne
#
function displayQuotedEnum () {
	local list="$@"
	local one_line_list="$(echo $list | tr '\n' ' ')"
	local trimmed_list="$(echo $one_line_list)"
	local quoted_list="'<b>${trimmed_list// /</b>', '<b>}</b>'"
	echo $quoted_list
}

##
# Affiche le sujet d'un ticket Redmine
# Le premier appel sollicite ws_redmine.inc.php qui lui-même exploite un WS Redmine,
# les suivants bénéficieront du fichier de cache $TWGIT_REDMINE_PATH.
#
# @param int $1 numéro de ticket Redmine
# @see getRedmineSubject()
#
function displayRedmineSubject () {
	local subject="$(getRedmineSubject "$1")"
	[ ! -z "$subject" ] && displayMsg redmine "$subject" || echo #processing 'Unknown Redmine subject.'
}

##
# Convertit une liste de valeurs en une ligne CSV au format suivant et l'affiche : "v1";"va""lue2";"v\'3"
#
# @param string $@ liste de valeurs
#
function convertList2CSV () {
	local row
	for v in "$@"; do
		v=${v//'"'/'""'}
		v=${v//"'"/"\\'"}
		row="$row;\"$v\""
	done
	echo ${row:1}
}

##
# Propose de supprimer une à une les branches qui ne sont plus trackées.
#
function clean_branches () {
	local tracked="$(git fetch --all -v --dry-run 2>&1 | grep '\->' | sed -r 's/^.* +([^ ]+) +\-> +.*$/\1/')"
	local locales="$(get_local_branches)"
	for branch in $locales; do
		if ! has $branch $tracked; then
			echo -n $(question "Local branch '$branch' is not tracked. Remove? [Y/N] ")
			read answer
			if [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
				exec_git_command "git branch -D $branch" "Remove local branch '$branch' failed!"
			fi
		fi
	done
}

##
# Permet la mise à jour automatique de l'application dans le cas où le .git est toujours présent.
# Tous les $TWGIT_UPDATE_NB_DAYS jours un fetch sera exécuté afin de proposer à l'utilisateur une
# éventuelle MAJ. Qu'il décline ou non, le prochain passage aura lieu dans à nouveau $TWGIT_UPDATE_NB_DAYS jours.
#
# A des fins de test : "touch -mt 1105200101 ~/twgit/.lastupdate"
#
# @param string $1 Si non vide, force la vérification de la présence d'une MAJ même si $TWGIT_UPDATE_NB_DAYS jours
#    ne se sont pas écoulés depuis le dernier test.
#
function autoupdate () {
	local is_forced="$1"
	cd "$TWGIT_ROOT_DIR"
	if git rev-parse --git-dir 1>/dev/null 2>&1; then
		[ ! -f "$TWGIT_UPDATE_PATH" ] && touch "$TWGIT_UPDATE_PATH"
		local elapsed_time=$(( ($(date -u +%s) - $(date -r "$TWGIT_UPDATE_PATH" +%s)) ))
		local interval=$(( $TWGIT_UPDATE_NB_DAYS * 86400 ))
		local answer=''

		if [ "$elapsed_time" -gt "$interval" ] || [ ! -z "$is_forced" ]; then
			# Update Git :
			processing "Fetch twgit repository for auto-update check..."
			git fetch
			compare_branches 'master' 'origin/master'
			local status=$?
			if [ "$status" = "1" ]; then
				echo -n $(question 'Update available! Do you want to update twgit (or manually: twgit update)? [Y/N] ')
				read answer
				if [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
					processing 'Update in progress...'
					git reset --hard && git pull
					> "$TWGIT_REDMINE_PATH"
				fi
			else
				processing 'Twgit already up-to-date.'
			fi

			# Prochain update :
			processing "Next auto-update check in $TWGIT_UPDATE_NB_DAYS days."
			touch "$TWGIT_UPDATE_PATH"

			# MAJ du système d'update d'autocomplétion :
			if [ ! -h "/etc/bash_completion.d/twgit" ]; then
				warn "New autocompletion update system request you execute just once this line (to adapt):"
				help_detail "sudo rm /etc/bash_completion.d/twgit && sudo ln -s ~/twgit/install/.bash_completion /etc/bash_completion.d/twgit && source ~/.bashrc"
			fi

			# Invite :
			if [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
				[ -z "$is_forced" ] && echo 'Thank you for re-enter your request.'
				exit 0
			fi
		fi
	elif [ ! -z "$is_forced" ]; then
		warn 'Git repositoy not found!'
	fi
	cd - 1>/dev/null
}
