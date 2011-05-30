#!/bin/bash


#--------------------------------------------------------------------
# User interface
#--------------------------------------------------------------------

# Map des colorations et en-têtes des messages du superviseur :
declare -A UI
UI=(
	[error.header]='\033[4;33m/!\\\033[0;37m '
	[error.color]='\033[1;31m'
	[info.color]='\033[1;37m'
	[info.bold.color]='\033[1;35m'
	[help.header]='\033[1;36m(i) '
	[help.color]='\033[0;36m'
	[help.bold.color]='\033[1;36m'
	[help_detail.header]='    '
	[help_detail.color]='\033[0;37m'
	[help_detail.bold.color]='\033[1;37m'
	[normal.color]='\033[0;37m'
	[warning.header]='\033[4;33m/!\\\033[0;37m '
	[warning.color]='\033[0;33m'
	[question.color]='\033[1;33m'
	[processing.color]='\033[1;30m'
)

function processing () {
	displayMsg processing "$1"
}

function info () {
	displayMsg info "$1"
}

function help () {
	displayMsg help "$1"
}

function help_detail () {
	displayMsg help_detail "$1"
}

function warn () {
	displayMsg warning "$1" >&2
}

function question () {
	displayMsg question "$1"
}

function error () {
	displayMsg error "$1" >&2
}

function die () {
	error "$1"
	echo
	exit 1
}

# Affiche un message dans la couleur et avec l'en-tête correspondant au type spécifié.
#
# @param string $1 type de message à afficher : conditionne l'éventuelle en-tête et la couleur
# @ parma string $2 message à afficher
function displayMsg () {
	local type=$1
	local msg=$2

	local is_defined=`echo ${!UI[*]} | grep "\b$type\b" | wc -l`
	[ $is_defined = 0 ] && echo "Unknown display type '$type'!" >&2 && exit 1
	local escape_color=$(echo ${UI[$type'.color']} | sed 's/\\/\\\\/g')
	local escape_bold_color=$(echo ${UI[$type'.bold.color']} | sed 's/\\/\\\\/g')

	if [ ! -z "${UI[$type'.header']}" ]; then
		echo -en "${UI[$type'.header']}"
	fi
	msg=$(echo "$msg" | sed "s/<b>/$escape_bold_color/g" | sed "s#</b>#$escape_color#g")
	echo -e "${UI[$type'.color']}$msg${UI['normal.color']}"
}


#--------------------------------------------------------------------
# Gestion des paramètres (et options) des fonctions
#
# Les options (une lettre max) peuvent être mélangées aux paramètres.
# Syntaxe admises (6 options ici) : -a -b-c -def
#
# Usage :
# function f () {
#	process_options "$@"
#	isset_option 'f' && echo "OK" || echo "NOK"
#	require_parameter 'my_name'
#	local release="$RETVAL"
#	...
# }
#--------------------------------------------------------------------

FCT_OPTIONS=''
FCT_PARAMETERS=''
RETVAL='' # to avoid subshell
function process_options {
	local param
	while [ $# -gt 0 ]; do
		# PB qd echo "-n"... : param=`echo "$1" | grep -P '^-[^-]' | sed s/-//g`
		[ ${#1} -gt 1 ] && [ ${1:0:1} = '-' ] && [ ${1:1:1} != '-' ] && param="${1:1}" || param=''
		param=$(echo "$param" | sed s/-//g)
		if [ ! -z "$param" ]; then
			FCT_OPTIONS="$FCT_OPTIONS $(echo $param | sed 's/\(.\)/\1 /g')"
		else
			FCT_PARAMETERS="$FCT_PARAMETERS $1"
		fi
		shift
	done
	FCT_PARAMETERS=${FCT_PARAMETERS:1}
}

function isset_option () {
	has $1 "$FCT_OPTIONS"
}

function require_parameter () {
	local name=$1
	local param="${FCT_PARAMETERS%% *}"
	FCT_PARAMETERS="${FCT_PARAMETERS:$((${#param}+1))}"
	if [ ! -z "$param" ]; then
		RETVAL=$param
	elif [ "$name" = '-' ]; then
		RETVAL=''
	else
		error "Missing argument <$name>!"
		usage
		exit 1
	fi
}



#--------------------------------------------------------------------
# Get
#--------------------------------------------------------------------

function get_all_branches () {
	git branch -a --no-color | sed 's/^[* ] //'
}

function get_local_branches () {
	git branch --no-color | sed 's/^[* ] //'
}

function get_remote_branches () {
	git branch -r --no-color | sed 's/^[* ] //'
}

function get_releases_in_progress () {
	git branch -r --no-merged $TWGIT_ORIGIN/HEAD | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_RELEASE" | sed 's/^[* ]*//'
}

function get_current_release_in_progress () {
	local releases="$(get_releases_in_progress)"
	local release="$(echo $releases | cut -d' ' -f1)"
	[[ $(echo $releases | wc -w) > 1 ]] && warn "More than one release in propress detected! Only '$release' will be treated here."
	echo $release
}

function get_merged_features () {
	local release="$1"
	local features="$(git branch -r --merged $release | grep $TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g')"
	local features_v2="$(get_features merged $release)"
	[ "$features" != "$features_v2" ] && die "Inconsistent result about merged features: '$features' != '$features_v2'!"
	echo $features
}

# $1 dans {merged, merged_in_progress, free}
function get_features () {
	local feature_type="$1"
	local release="$2"

	if [ -z "$release" ]; then
		if [ "$feature_type" = 'merged' ] || [ "$feature_type" = 'merged_in_progress' ]; then
			echo ''
		elif [ "$feature_type" = 'free' ]; then
			git branch -r --no-merged $TWGIT_ORIGIN/HEAD | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g'
		fi
	else
		local return_features=''
		local features_merged=$(git branch -r --merged $release | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
		local features=$(git branch -r | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')
		local head_rev=$(git rev-parse $TWGIT_ORIGIN/HEAD)
		local release_rev=$(git rev-parse $release)

		local f_rev merge_base master_merge_base
		for f in $features; do
			f_rev=$(git rev-parse $f)
			merge_base=$(git merge-base $release_rev $f_rev)
			master_merge_base=$(git merge-base $release_rev $head_rev)
			if [ "$merge_base" = "$f_rev" ]; then
				[ "$feature_type" = 'merged' ] && return_features="$return_features $f"
			elif [ "$merge_base" != "$master_merge_base" ]; then
				[ "$feature_type" = 'merged_in_progress' ] && return_features="$return_features $f"
			elif [ "$feature_type" = 'free' ]; then
				return_features="$return_features $f"
			fi
		done
		echo ${return_features:1}
	fi
}

function get_current_branch () {
	git branch --no-color | grep '^\* ' | grep -v 'no branch' | sed 's/^* //g'
}

function get_all_tags () {
	git tag | sort -n
}

function get_last_tag () {
	git tag | sort -rn | head -n1
}

function get_next_version () {
	local change_type="$1"
	local current_version="$2"

	local major=$(echo $current_version | cut -d. -f1)
	local minor=$(echo $current_version | cut -d. -f2)
	local revision=$(echo $current_version | cut -d. -f3)

	case "$change_type" in
		major) let major++ ;;
		minor) let minor++ ;;
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



#--------------------------------------------------------------------
# Assertions
#--------------------------------------------------------------------

function assert_git_configured () {
	if ! git config --global user.name 1>/dev/null; then
		die "Unknown user.name! Do: git config --global user.name 'Firstname Lastname'"
	elif ! git config --global user.email 1>/dev/null; then
		die "Unknown user.email! Do: git config --global user.email 'firstname.lastname@twenga.com'"
	fi
}

function assert_git_repository () {
	local errormsg=$(git rev-parse --git-dir 2>&1 1>/dev/null)
	[ ! -z "$errormsg" ] && die "[Git error msg] $errormsg"
}

function assert_branches_equal () {
	processing 'Compare remote and local branches...'
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
			die "And local branch '$1' may be fast-forwarded!"
		elif [ $status -eq 2 ]; then
			# Warn here, since there is no harm in being ahead
			warn "And local branch '$1' is ahead of '$2'."
		else
			die "Branches need merging first!"
		fi
	fi
}

function assert_new_local_branch () {
	if has $1 $(get_local_branches); then
		die "Local branch '$1' already exists! Pick another name."
	fi
}

function assert_clean_working_tree () {
	processing 'Check clean working tree...'
	if [ `git status --porcelain --ignore-submodules=all | wc -l` -ne 0 ]; then
		error 'Untracked files or changes to be committed in your working tree!'
		exec_git_command 'git status'
		exit 1
	fi
}

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

function assert_valid_tag_name () {
	local tag="$1"
	assert_valid_ref_name "$tag"
	processing 'Check valid tag name...'
	$(echo "$tag" | grep -qP '^'$TWGIT_PREFIX_TAG'[0-9]+\.[0-9]+\.[0-9]+$') || die "Unauthorized tag name: '$tag'!"
}

function assert_working_tree_is_not_on_delete_branch () {
	local branch="$1"
	processing "Check current branch..."
	if [ $(get_current_branch) = "$branch" ]; then
		 processing "Cannot delete the branch '$branch' which you are currently on! So:"
		 exec_git_command "git checkout $TWGIT_MASTER" "Could not checkout '$TWGIT_MASTER'!"
	fi
}

function assert_tag_exists () {
	processing 'Get last tag...'
	local last_tag="$(get_last_tag)"
	[ -z "$last_tag" ] && die 'No tag exists!' || echo "Last tag: $last_tag"
}



#--------------------------------------------------------------------
# Traitements
#--------------------------------------------------------------------

function process_fetch () {
	local option="$1"
	if [ -z "$option" ] || ! isset_option "$option"; then
		exec_git_command "git fetch --prune $TWGIT_ORIGIN" "Could not fetch '$TWGIT_ORIGIN'!"
		[ ! -z "$option" ] && echo
	fi
}

function process_first_commit () {
	local commit_msg=$(printf "$TWGIT_FIRST_COMMIT_MSG" "$1" "$2")
	#exec_git_command "git commit --allow-empty -m \"$commit_msg\"" 'Could not make initial commit!'

	processing "$TWGIT_GIT_COMMAND_PROMPTgit commit --allow-empty -m \"$commit_msg\""
	git commit --allow-empty -m "$commit_msg" || die "$error_msg"
}

function process_push_branch () {
	local branch="$1"
	local is_remote_exists="$2"
	local git_options=$([ $is_remote_exists = '0' ] && echo '--set-upstream' || echo '')
	exec_git_command "git push $git_options $TWGIT_ORIGIN $branch" "Could not push branch '$branch'!"
}

# ne pas utiliser si des quotes sont nécessaires pour délimiter des paramètres de la commande...
# http://mywiki.wooledge.org/BashFAQ/050
function exec_git_command () {
	local cmd="$1"
	local error_msg="$2"
	processing "$TWGIT_GIT_COMMAND_PROMPT$cmd"
	$cmd || die "$error_msg"
}

function remove_local_branch () {
	local branch="$1"
	if has $branch $(get_local_branches); then
		exec_git_command "git branch -D $branch" "Remove local branch '$branch' failed!"
	else
		processing "Local branch '$branch' not found."
	fi
}

function remove_remote_branch () {
	local branch="$1"
	if has "$TWGIT_ORIGIN/$branch" $(get_remote_branches); then
		exec_git_command "git push $TWGIT_ORIGIN :$branch" "Delete remote branch '$TWGIT_ORIGIN/$branch' failed "
		if [ $? -ne 0 ]; then
			processing "Remove remote branch '$TWGIT_ORIGIN/$branch' failed! Maybe already deleted... so:"
			exec_git_command "git remote prune $TWGIT_ORIGIN" "Prune failed!"
		fi
	else
		die "Remote branch '$TWGIT_ORIGIN/$branch' not found!"
	fi
}

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
# Autre...
#--------------------------------------------------------------------

function escape () {
	echo "$1" | sed 's/\([\.\+\$\*]\)/\\\1/g'
}

function has () {
	local item=$1; shift
	echo " $@ " | grep -q " $(escape $item) "
	#local n=$(echo " $@ " | grep " $(escape $item) " | wc -l)
	#[ $n = '0' ] && echo 0 || echo 1
}


# Tests whether branches and their "origin" counterparts have diverged and need
# merging first. It returns error codes to provide more detail, like so:
#
# 0    Branch heads point to the same commit
# 1    First given branch needs fast-forwarding
# 2    Second given branch needs fast-forwarding
# 3    Branch needs a real merge
# 4    There is no merge base, i.e. the branches have no common ancestors
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

function display_branches () {
	local title="$1"
	local branches="$2"

	if [ -z "$branches" ]; then
		info 'No such branch exists.'; echo
	else
		for branch in $branches; do
			info "$title$branch"
			git show $branch --pretty=medium | grep -v '^Merge: ' | head -n4
		done
	fi
}
