#!/bin/bash


#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# User interface
#____________________________________________________________________

# Map des colorations et en-têtes des messages du superviseur :
declare -A UI
UI=(
	[error.header]='\033[0;33m/!\ '
	[error.color]='\033[1;31m'
	[info.color]='\033[1;37m'
	[help.header]='\033[1;36m(i) '
	[help.color]='\033[0;36m'
	[help_detail.header]='    '
	[help_detail.color]='\033[0;37m'
	[help_detail.bold.color]='\033[1;37m'
	[normal.color]='\033[0;37m'
	[warning.header]='\033[33m/!\ '
	[warning.color]='\033[0;33m'
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



#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# Get
#____________________________________________________________________

function get_all_branches () { 
	git branch -a --no-color | sed 's/^[* ] //'
}

function get_local_branches () { 
	git branch --no-color | sed 's/^[* ] //'
}

function get_remote_branches () { 
	git branch -r --no-color | sed 's/^[* ] //'
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
	local next_version
	
	local types='major minor build'
	local major=$(echo $current_version | cut -d. -f1)
	local minor=$(echo $current_version | cut -d. -f2)
	local build=$(echo $current_version | cut -d. -f3)
	
	case "$change_type" in
		major) let major++ ;;
		minor) let minor++ ;;
		build) let build++ ;;
		*) die "Invalid version change type: '$change_type'!" ;;
	esac
	echo "$major.$minor.$build"
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



#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# Assertions
#____________________________________________________________________

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
	if [ $(has $1 $(get_local_branches)) = '0' ]; then
		die "Local branch '$1' does not exist and is required!"
	elif [ $(has $2 $(get_remote_branches)) = '0' ]; then
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

function require_arg () {
	if [ -z "$2" ]; then
		error "Missing argument <$1>!"
		usage
		exit 1
	fi	
}

function assert_clean_working_tree () {
	processing 'Check clean working tree...'
	if [ `git status --porcelain --ignore-submodules=all | wc -l` -ne 0 ]; then
		error 'Untracked files or changes to be committed in your working tree!'
		processing 'git status'
		git status
		exit 1
	fi
}

function assert_valid_ref_name () {
	processing 'Check valid ref name...'
	git check-ref-format --branch "$1" 1>/dev/null 2>&1
	if [ $? -ne 0 ]; then
		die "'$1' is not a valid reference name!"
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
	assert_valid_ref_name
	processing 'Check valid tag name...'
	$(echo "$1" | grep -qP '^'$TWGIT_PREFIX_TAG'[0-9]+\.[0-9]+\.[0-9]+$') || die 'Unauthorized tag name!'
}



#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# Tools
#____________________________________________________________________

function escape () {
	echo "$1" | sed 's/\([\.\+\$\*]\)/\\\1/g'
}

function has () {
	local item=$1; shift
	#echo " $@ " | grep -q " $(escape $item) "
	local n=$(echo " $@ " | grep " $(escape $item) " | wc -l)
	[ $n = '0' ] && echo 0 || echo 1
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
