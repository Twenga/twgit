#!/bin/bash

function escape {
	echo "$1" | sed 's/\([\.\+\$\*]\)/\\\1/g'
}

# set logic
function has {
	local item=$1; shift
	echo " $@ " | grep -q " $(escape $item) "
}

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

function assert_branch_absent {
	if has $1 $(get_all_branches); then
		echo "Branch '$1' already exists. Pick another name."
	fi
}