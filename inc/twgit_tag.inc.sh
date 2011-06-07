#!/bin/bash

assert_git_repository

##
# Affiche l'aide de la commande tag.
#
function usage () {
	echo; help 'Usage:'
	help_detail 'twgit tag <action>'
	echo; help 'Available actions are:'
	help_detail '<b>list</b>'
	help_detail '    List 5 last tags. Add <b>-f</b> to do not make fetch.'; echo
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
# Liste les tags.
# Gère l'option '-f' permettant d'éviter le fetch.
#
function cmd_list () {
	process_options "$@"
	process_fetch 'f'

	local max='5'
	local tags=$(get_all_tags $max)
	help "List $max last tags:"
	if [ -z "$tags" ]; then
		info 'No tag exists.'; echo
	else
		for tag in $tags; do
			info "Tag: $tag"
			git show $tag --pretty=medium | head -n 4 | tail -n +2
		done
	fi
}
