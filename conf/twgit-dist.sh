#!/usr/bin/env bash

##
# twgit config file
#
#
#
# Copyright (c) 2011 Twenga SA
# Copyright (c) 2012-2013 Geoffroy Aubry <geoffroy.aubry@free.fr>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
# for the specific language governing permissions and limitations under the License.
#
# @copyright 2011 Twenga SA
# @copyright 2012-2013 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @license http://www.apache.org/licenses/LICENSE-2.0
#



TWGIT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TWGIT_INC_DIR="$TWGIT_ROOT_DIR/inc"
TWGIT_CONF_DIR="$TWGIT_ROOT_DIR/conf"
TWGIT_TMP_DIR="/tmp"

TWGIT_BASH_EXEC="/bin/bash"
TWGIT_EXEC="$TWGIT_BASH_EXEC $TWGIT_ROOT_DIR/twgit"

# Name of file in root directory of each user repository to cache Redmine and Github feature's subject:
TWGIT_FEATURES_SUBJECT_FILENAME='.twgit_features_subject'
TWGIT_UPDATE_PATH="$TWGIT_ROOT_DIR/.lastupdate"
TWGIT_UPDATE_NB_DAYS=2
TWGIT_UPDATE_AUTO=1	# Laisser à 1 pour autoriser la MAJ auto.

TWGIT_HISTORY_LOG_PATH="$TWGIT_ROOT_DIR/.history.log"
TWGIT_HISTORY_ERROR_PATH="$TWGIT_ROOT_DIR/.history.error"
TWGIT_HISTORY_SEPARATOR="----------------------------------------------------------------------\n[%s] %s\n"

TWGIT_PREFIX_FEATURE='feature-'
TWGIT_PREFIX_RELEASE='release-'
TWGIT_PREFIX_HOTFIX='hotfix-'
TWGIT_PREFIX_TAG='v'
TWGIT_PREFIX_DEMO='demo-'

TWGIT_ORIGIN='origin'
TWGIT_STABLE='stable'

TWGIT_PREFIX_COMMIT_MSG='[twgit] '
TWGIT_FIRST_COMMIT_MSG="${TWGIT_PREFIX_COMMIT_MSG}Init %s '%s'%s."	# ie: [twgit] Init feature 'feature-1': full title.
TWGIT_GIT_COMMAND_PROMPT='git# '
TWGIT_GIT_MIN_VERSION='1.7.2.0'

TWGIT_DEFAULT_NB_COMMITTERS='3'

# Default rendering option for twgit feature list, to choose in {'', 'c', 'd', 'x'},
# where 'c' stands for compact, 'd' for detailed and 'x' for eXtremely compact (CSV).
TWGIT_FEATURE_LIST_DEFAULT_RENDERING_OPTION=''

TWGIT_EMAIL_DOMAIN_NAME=''	# e.g. twenga.com

TWGIT_MAX_RETRIEVE_TAGS_NOT_MERGED=3
TWGIT_MAX_TAG_LIST_TO_SHOW=5

TWGIT_FEATURE_SUBJECT_CONNECTOR=''			    # in {'', 'github', 'redmine', 'jira'}
TWGIT_FEATURE_SUBJECT_CONNECTOR_PATH="$TWGIT_INC_DIR/connectors/feature_subject_%s.sh"	# où %s est un $TWGIT_FEATURE_SUBJECT_CONNECTOR
TWGIT_FEATURE_SUBJECT_REDMINE_API_KEY=''	    # API key is a 40-byte hexadecimal string.
TWGIT_FEATURE_SUBJECT_REDMINE_DOMAIN=''		    # e.g. 'www.redmine.org', with optionally scheme: 'http://', 'https://' (default).
TWGIT_FEATURE_SUBJECT_GITHUB_USER=''		    # e.g. 'Twenga'
TWGIT_FEATURE_SUBJECT_GITHUB_REPOSITORY=''	    # e.g. 'twgit'
TWGIT_FEATURE_SUBJECT_JIRA_DOMAIN=''            # e.g. 'www.abc.xyz'
TWGIT_FEATURE_SUBJECT_JIRA_CREDENTIAL_BASE64='' # base64 (login:password)

# All the files designed in the TWGIT_VERSION_INFO_PATH list will be
# parsed in order to search for $Id$ or $Id:X.Y.Z$ and replace with
# the current version on twgit init, twgit release start, and twgit hotfix start.
# Example: being in v1.2.3 and calling twgit release start will result in replacing all tags with $Id:1.3.0$.
# /!\ File list is comma separated: TWGIT_VERSION_INFO_PATH='file1.php,file2.php'
TWGIT_VERSION_INFO_PATH=''

##
# Colors and decorations types.
# MUST define following types:
#     error, feature_subject, help, help_detail, info, normal, ok, processing, question, warning.
#
# For each type, message will be displayed as follows (.header and .bold are optional):
#     '<type.header><type>message with <type.bold>bold section<type>.\033[0m'
#
# Color codes :
#   - http://www.tux-planet.fr/les-codes-de-couleurs-en-bash/
#   - http://confignewton.com/wp-content/uploads/2011/07/bash_color_codes.png
#
# @var associative array
# @see inc/coloredUI.inc.sh for more details.
#
declare -A CUI_COLORS=(
    [error]='\033[1;31m'
    [error.bold]='\033[1;33m'
    [error.header]='\033[1m\033[4;33m/!\\\033[0;37m '
    [feature_subject]='\033[1;34m'
    [help]='\033[0;36m'
    [help.bold]='\033[1;36m'
    [help.header]='\033[1;36m(i) '
    [help_detail]='\033[0;37m'
    [help_detail.bold]='\033[1;37m'
    [help_detail.header]='    '
    [info]='\033[1;37m'
    [normal]='\033[0;37m'
    [ok]='\033[0;32m'
    [processing]='\033[1;30m'
    [question]='\033[1;33m'
    [question.bold]='\033[1;37m'
    [warning]='\033[0;33m'
    [warning.bold]='\033[1;33m'
    [warning.header]='\033[1m\033[4;33m/!\\\033[0;37m '
    [current_branch]='\033[1;31m'
)
