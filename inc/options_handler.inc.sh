#!/bin/bash

#--------------------------------------------------------------------
# Gestionnaire des paramètres et options (avec le tiret simple) des fonctions.
#
# Les options (une lettre max) peuvent être mélangées aux paramètres.
# Syntaxe admises :
#     - 6 options dans cet exemple, les X sont des paramètres standards facultatifs :
#     [X] -a [X] -b-c [X] -def [X]
#
# Usage :
# function f () {
#	process_options "$@"
#	isset_option 'f' && echo "OK" || echo "NOK"
#	require_parameter 'my_release'
#	local release="$RETVAL"
#	...
# }
#
# @author Geoffroy Aubry
#--------------------------------------------------------------------

# Globales du système de gestion :
FCT_OPTIONS=''		# concaténation des options sans les tirets, avec des espaces entre.
FCT_PARAMETERS=''	# concaténation des paramètres non options, avec des espaces entre.
RETVAL=''			# global to avoid subshell...

##
# Analayse les paramètres et les répartis entre options et paramètres standards.
# Rempli les tableaux globaux $FCT_OPTIONS et $FCT_PARAMETERS.
#
# @param string $@ liste de paramètres à analyser
#
function process_options {
	local param
	while [ $# -gt 0 ]; do
		# PB pour récupérer la lettre option quand echo "-n"...
		# Du coup ceci ne fonctionne pas : param=`echo "$1" | grep -P '^-[^-]' | sed s/-//g`
		# Parade :
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

##
# Est-ce que lavaleur spécifiée fait partie de $FCT_OPTIONS ?
#
# @param string $1 valeur à rechercher
# @return 1 si présent, 0 sinon
# @see has()
#
function isset_option () {
	#has $1 "$FCT_OPTIONS"
	local item=$1; shift
	echo " $FCT_OPTIONS " | grep -q " $(echo "$item" | sed 's/\([\.\+\$\*]\)/\\\1/g') "
}

##
# Dépile le prochain paramètre de $FCT_PARAMETERS et le stock dans la globale $RETVAL.
#
# @param string $1 nom du paramètre demandé, qui servira pour le message d'erreur en cas de paramètre absent
# Si le nom vaut '-' alors le paramètre est considéré comme optionnel.
#
function require_parameter () {
	local name=$1

	# On extrait le pâté de paramètres le plus à gauche :
	local param="${FCT_PARAMETERS%% *}"

	# On met à jour les paramètres restant à traiter :
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