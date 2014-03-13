#!/bin/bash

##
# twgit
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



##
# Retrieve and display subject of a Redmine's issue.
#
# @param string $1 issue number or project name
#
ref="$1"
if [[ "$TWGIT_FEATURE_SUBJECT_REDMINE_DOMAIN" =~ ^https?:// ]]; then
    scheme=''
else
    scheme='https://'
fi
issue_url="$scheme$TWGIT_FEATURE_SUBJECT_REDMINE_DOMAIN/issues/$ref.json?key=$TWGIT_FEATURE_SUBJECT_REDMINE_API_KEY"
project_url="$scheme$TWGIT_FEATURE_SUBJECT_REDMINE_DOMAIN/projects/$ref.json?key=$TWGIT_FEATURE_SUBJECT_REDMINE_API_KEY"
wget_cmd='wget --no-check-certificate --timeout=3 -q -O - --no-cache'

# Python or PHP ?
language='?'
which python 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
    language='python'
else
    which php 1>/dev/null 2>&1
    if [ $? -eq 0 ]; then
        language='php'
    fi
fi

# Convert JSON with Python or PHP:
if [ "$language" = 'python' ]; then
    if [[ "$ref" =~ ^[0-9]+$ ]]; then
        ($wget_cmd $issue_url \
        | python -c 'import sys,json;s=sys.stdin.read();
if s!="": data=json.loads(s); print data["issue"]["subject"].encode("utf8")')
        2>/dev/null
    else
        ($wget_cmd $project_url \
        | python -c 'import sys,json;s=sys.stdin.read();
if s!="": data=json.loads(s); print data["project"]["name"].encode("utf8")')
        2>/dev/null
    fi
elif [ "$language" = 'php' ]; then
    if [[ "$ref" =~ ^[0-9]+$ ]]; then
        ($wget_cmd $issue_url \
        | php -r '$o = json_decode(file_get_contents("php://stdin")); if ($o !== NULL) {print_r($o->issue->subject);}')
        2>/dev/null
    else
        ($wget_cmd $project_url \
        | php -r '$o = json_decode(file_get_contents("php://stdin")); if ($o !== NULL) {print_r($o->project->name);}')
        2>/dev/null
    fi
else
    echo "Language '$language' not handled!" >&2
    exit 1
fi
