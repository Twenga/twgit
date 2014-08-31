#!/usr/bin/env bash

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
# Retrieve and display subject of a Github's issue.
# Compatible Github API v3: http://developer.github.com/v3/.
#
# @param string $1 issue name
# /api/v3/projects/brandzofferz%2Fbo/issues/1?private_token=GNR9tuTVGXBTxYkpsQDa
issue="$1"

if [[ "$TWGIT_FEATURE_SUBJECT_GITLAB_DOMAIN" =~ ^https?:// ]]; then
    scheme=''
else
    scheme='http://'
fi
url="${scheme}${TWGIT_FEATURE_SUBJECT_GITLAB_DOMAIN}"
url="${url}/api/v3/projects/${TWGIT_FEATURE_SUBJECT_GITLAB_GROUP}%2F${TWGIT_FEATURE_SUBJECT_GITLAB_REPOSITORY}/issues/${issue}"
url="${url}?private_token=${TWGIT_FEATURE_SUBJECT_GITLAB_PRIVATE_TOKEN}"

if ${has_wget}; then
    cmd="wget --no-check-certificate --timeout=3 --user-agent=Twenga-twgit -q -O - --no-cache"
else
    cmd="curl --insecure --max-time 3 --user-agent Twenga-twgit --silent -H \"Cache-control: no-cache\""
fi

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
    ($cmd $url | python -c 'import sys,json;s=sys.stdin.read();
if s!="": data=json.loads(s); print data["title"].encode("utf8")')
    2>/dev/null
elif [ "$language" = 'php' ]; then
    ($cmd $url \
    | php -r '$o = json_decode(file_get_contents("php://stdin")); if ($o !== NULL) {print_r($o->title);}')
    2>/dev/null
else
    echo "Language '$language' not handled!" >&2
    exit 1
fi
