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
# Retrive and display subject of a Jira's issue.
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
curl_cmd="curl -X GET -H \"Authorization: Basic $TWGIT_FEATURE_SUBJECT_JIRA_CREDENTIAL_BASE64\" -H \"Content-Type: application/json\" $issue_url"

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
    data=$(eval $curl_cmd)
    if [ ! -z "$data" ]; then
        echo $data | python -c "import json,sys;s=sys.stdin.read();s=s.replace('\r\n', '');s=json.loads(s);print s['fields']['summary'];"
    fi
elif [ "$language" = 'php' ]; then
        ($curl_cmd \
        | php -r '$o = json_decode(file_get_contents("php://stdin")); if ($o !== NULL) {print_r($o->fields->summary);}')
        2>/dev/null
else
    echo "Language '$language' not handled!" >&2
    exit 1
fi
