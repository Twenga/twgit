#!/bin/bash

##
# twgit
#
#
#
# Copyright (c) 2014 Romain Derocle <rderocle@gmail.com>
# Copyright (c) 2014 Geoffroy Aubry <geoffroy.aubry@free.fr>
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
# @copyright 2014 Romain Derocle <rderocle@gmail.com>
# @copyright 2014 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @license http://www.apache.org/licenses/LICENSE-2.0
#



##
# Retrieve and display subject of a Jira's issue.
#
# @param string $1 issue number or project name
#
issue="$1"
if [[ "$TWGIT_FEATURE_SUBJECT_JIRA_DOMAIN" =~ ^https?:// ]]; then
    scheme=''
else
    scheme='https://'
fi
issue_url="$scheme$TWGIT_FEATURE_SUBJECT_JIRA_DOMAIN/rest/api/latest/issue/$issue"
wget_cmd="wget --no-check-certificate --timeout=3 -q -O - --no-cache --header \"Authorization: Basic $TWGIT_FEATURE_SUBJECT_JIRA_CREDENTIAL_BASE64\" --header \"Content-Type: application/json\" $issue_url"

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
language='php'

# Convert JSON with Python or PHP:
if [ "$language" = 'python' ]; then
    data=$(eval $wget_cmd)
    if [ ! -z "$data" ]; then
        echo $data | python -c "import json,sys;s=sys.stdin.read();s=s.replace('\r\n', '');s=json.loads(s);print s['fields']['summary'];" 2>/dev/null
    fi
elif [ "$language" = 'php' ]; then
    data=$(eval $wget_cmd)
    if [ ! -z "$data" ]; then
        echo $data | php -r '$o = json_decode(file_get_contents("php://stdin")); if (!empty($o)){print_r($o->fields->summary);}'
    fi
else
    echo "Language '$language' not handled!" >&2
    exit 1
fi
