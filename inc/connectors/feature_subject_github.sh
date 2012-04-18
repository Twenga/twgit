#!/bin/bash

##
# twgit
#
# Copyright (c) 2011 Twenga SA.
#
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/
# or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
#
# @copyright 2012 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @license http://creativecommons.org/licenses/by-nc-sa/3.0/
#



##
# Retrive and display subject of a Github's issue.
#
# @param string $1 issue name
#
issue="$1"
url="$(printf "https://github.com/api/v2/json/issues/show/%s/%s/%s" \
        "$TWGIT_FEATURE_SUBJECT_GITHUB_USER" \
        "$TWGIT_FEATURE_SUBJECT_GITHUB_REPOSITORY" \
        "$issue")"
(wget -q -O - --no-cache $url \
    | php -r '$o = json_decode(file_get_contents("php://stdin")); if ($o !== NULL) {print_r($o->issue->title);}')
    2>/dev/null