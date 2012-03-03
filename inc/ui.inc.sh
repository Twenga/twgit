#!/bin/bash

##
# User interface.
#
# Copyright (c) 2011 Twenga SA.
#
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/
# or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
#
# @copyright 2011 Twenga SA
# @license http://creativecommons.org/licenses/by-nc-sa/3.0/
#

# Map des colorations et en-têtes des messages :
declare -A UI
UI=(
    [error.header]='\033[1m\033[4;33m/!\\\033[0;37m '
    [error.color]='\033[1;31m'
    [info.color]='\033[1;37m'
    [feature_subject.color]='\033[1;34m'
    [help.header]='\033[1;36m(i) '
    [help.color]='\033[0;36m'
    [help.bold.color]='\033[1;36m'
    [help_detail.header]='    '
    [help_detail.color]='\033[0;37m'
    [help_detail.bold.color]='\033[1;37m'
    [normal.color]='\033[0;37m'
    [warning.header]='\033[1m\033[4;33m/!\\\033[0;37m '
    [warning.color]='\033[0;33m'
    [warning.bold.color]='\033[1;33m'
    [question.color]='\033[1;33m'
    [processing.color]='\033[1;30m'
    [ok.color]='\033[0;32m'
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
    displayMsg warning "$1"
}

function question () {
    displayMsg question "$1"
}

function error () {
    displayMsg error "$1"
}

function die () {
    error "$1" >&2
    echo
    exit 1
}

##
# Affiche un message dans la couleur du type spécifié ("$type.color").
# S'il existe un en-tête "$type.header" dans la map UI, alors il viendra préfixer le message spécifié.
# Enfin s'il existe un en-tête "$type.bold.color" dans la map UI, alors le texte encadré de balises <b> et </b> sera
# dans cette couleur. Dans tous les cas ces balises seront supprimées de la sortie.
#
# @param string $1 type de message à afficher : conditionne l'éventuelle en-tête et la couleur
# @param string $2 message à afficher
#
function displayMsg () {
    local type=$1
    local msg=$2
    local header

    local is_defined=`echo ${!UI[*]} | grep "\b$type\b" | wc -l`
    [ $is_defined = 0 ] && echo "Unknown display type '$type'!" >&2 && exit 1
    local escape_color=$(echo ${UI[$type'.color']} | sed 's/\\/\\\\/g')
    local escape_bold_color=$(echo ${UI[$type'.bold.color']} | sed 's/\\/\\\\/g')

    if [ ! -z "${UI[$type'.header']}" ]; then
        header="${UI[$type'.header']}"
    else
        header=''
    fi
    msg=$(echo "$msg" | sed "s/<b>/$escape_bold_color/g" | sed "s#</b>#$escape_color#g")
    echo -e "$header${UI[$type'.color']}$msg${UI['normal.color']}"
}
