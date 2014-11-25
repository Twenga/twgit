#!/bin/bash

##
# twgit
#
#
#
# Copyright (c) 2014 Julien Pottier <julien.pottier@sensiolabs.com>
# Copyright (c) 2014 Laurent Toussaint <lt.laurent.toussaint@gmail.com>
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
# @copyright 2014 Julien Pottier <julien.pottier@sensiolabs.com>
# @copyright 2014 Laurent Toussaint <lt.laurent.toussaint@gmail.com>
# @license http://www.apache.org/licenses/LICENSE-2.0
#



##
# Retrieve and display subject of a Trello's issue.
#
# @param string $1 issue number or project name
#
issue="$1"
url="$(printf "%s/1/cards/%s?key=%s\&token=%s" \
        "$TWGIT_FEATURE_SUBJECT_TRELLO_DOMAIN" \
        "$issue" \
        "$TWGIT_FEATURE_SUBJECT_TRELLO_APPLICATION_KEY" \
        "$TWGIT_FEATURE_SUBJECT_TRELLO_TOKEN")"

if ${has_wget}; then
    cmd="wget --no-check-certificate --timeout=3 -q -O - --no-cache"
else
    cmd="curl --insecure --max-time 3 --silent -H \"Cache-control: no-cache\""
fi
cmd="${cmd} ${url}"

data=$(eval $cmd)

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
    data=$(eval $cmd)
    if [ ! -z "$data" ]; then
        echo $data | python -c "import json,sys;s=sys.stdin.read();s=s.replace('\r\n', '');s=json.loads(s);print s['name'].encode('utf8');" 2>/dev/null
    fi
elif [ "$language" = 'php' ]; then
    data=$(eval $cmd)
    if [ ! -z "$data" ]; then
        echo $data | php -r '$o = json_decode(file_get_contents("php://stdin")); echo $o->name;' 2>/dev/null
    fi
else
    echo "Language '$language' not handled!" >&2
    exit 1
fi

exit 0