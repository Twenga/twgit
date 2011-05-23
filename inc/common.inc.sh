#!/bin/bash

# output

# Map des colorations et en-têtes des messages du superviseur :
declare -A UI
UI=(
	[error.header]='\033[33m /!\ '
	[error.color]='\033[1;31m'
	[error_detail.color]='\033[1;31m'
	[info.header]='\033[1;36m (i) '
	[info.color]='\033[0;39m'
	[normal.color]='\033[0;39m'
	[subtitle.color]='\033[1;35m'
	[success.color]='\033[1;32m'
	[title.color]='\033[1;36m'
	[warning.header]='\033[33m /!\ '
	[warning.color]='\033[0;33m'
)

function warn { 
	displayMsg warning "$1" >&2; 
}

function die { 
	displayMsg error "$1" >&2;
	exit 1;
}

# Affiche un message dans la couleur et avec l'en-tête correspondant au type spécifié.
#
# @param string $1 type de message à afficher : conditionne l'éventuelle en-tête et la couleur
# @ parma string $2 message à afficher
function displayMsg {
	local type=$1
	local msg=$2
	
	local is_defined=`echo ${!UI[*]} | grep "\b$type\b" | wc -l`
	[ $is_defined = 0 ] && echo "Unknown display type '$type'!" >&2 && exit
	
	if [ ! -z "${UI[$type'.header']}" ]; then
		echo -en "${UI[$type'.header']}"
	fi
	echo -e "${UI[$type'.color']}$msg${UI['normal.color']}"
}

function escape {
	echo "$1" | sed 's/\([\.\+\$\*]\)/\\\1/g'
}

# set logic
function has {
	local item=$1; shift
	echo " $@ " | grep -q " $(escape $item) "
}

#
# Get
#

function get_all_branches { 
	( git branch --no-color; git branch -r --no-color) | sed 's/^[* ] //';
}

function get_local_branches { 
	git branch --no-color | sed 's/^[* ] //';
}

function get_remote_branches { 
	git branch -r --no-color | sed 's/^[* ] //'; 
}

function get_current_branch { 
	git branch --no-color | grep '^\* ' | grep -v 'no branch' | sed 's/^* //g'
}

#
# Assertions
#

function assert_branch_absent {
	if has $1 $(get_all_branches); then
		echo "Branch '$1' already exists. Pick another name."
	fi
}

function assert_git_repository {
	if ! git rev-parse --git-dir >/dev/null 2>&1; then
		die "fatal: Not a git repository"
	fi
}