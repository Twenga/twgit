
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# Customize prompt.
# Copy into ~/.bash_profile
#____________________________________________________________________


function get_git_branch () {
	local branch=$(git branch --no-color 2>/dev/null | grep -P '^\*' | sed 's/* //')
	[ ! -z "$branch" ] && echo " \[\e[1;30m\]git\[\e[1;35m\]$branch"
}

export PROMPT_COMMAND='PS1="\[\e[0;32m\]\h:\w$(get_git_branch)\[\e[1;32m\]\\$\[\e[m\] "'
