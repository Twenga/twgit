#!/bin/bash

##
# twgit config file
#
# Copyright (c) 2011 Twenga SA.
#
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/
# or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
#
# @copyright 2011 Twenga SA
# @copyright 2012 Geoffroy Aubry <gaubry@hi-media.com>
# @license http://creativecommons.org/licenses/by-nc-sa/3.0/
#



TWGIT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TWGIT_INC_DIR="$TWGIT_ROOT_DIR/inc"
TWGIT_CONF_DIR="$TWGIT_ROOT_DIR/conf"

TWGIT_BASH_EXEC="/bin/bash"
TWGIT_EXEC="$TWGIT_BASH_EXEC $TWGIT_ROOT_DIR/twgit"

TWGIT_FEATURES_SUBJECT_PATH="$TWGIT_ROOT_DIR/.features_subject"
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

TWGIT_EMAIL_DOMAIN_NAME=''	# e.g. twenga.com

TWGIT_MAX_RETRIEVE_TAGS_NOT_MERGED=3

TWGIT_FEATURE_SUBJECT_CONNECTOR=''	# in {'', 'github', 'redmine'}
TWGIT_FEATURE_SUBJECT_CONNECTOR_PATH="$TWGIT_INC_DIR/connectors/feature_subject_%s.sh"	# où %s est un $TWGIT_FEATURE_SUBJECT_CONNECTOR
TWGIT_FEATURE_SUBJECT_REDMINE_API_KEY=''	# API key is a 40-byte hexadecimal string.
TWGIT_FEATURE_SUBJECT_REDMINE_URL="https://[domain]/issues/%s.json?key=$TWGIT_FEATURE_SUBJECT_REDMINE_API_KEY"	# où %s est le nom court d'une feature
TWGIT_FEATURE_SUBJECT_GITHUB_URL='https://github.com/api/v2/json/issues/show/[user]/[repo]/%s'	# où %s est le nom court d'une feature
