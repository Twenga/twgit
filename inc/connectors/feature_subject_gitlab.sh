#!/usr/bin/env bash

##
# twgit
#
#
#
# Copyright (c) 2014 Karl Marques <marques.karl@live.fr>
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
# @copyright 2014 Karl Marques <marques.karl@live.fr>
# @copyright 2014 Laurent Toussaint <lt.laurent.toussaint@gmail.com>
# @license http://www.apache.org/licenses/LICENSE-2.0
#

##
# Retrieve and display subject of a Gitlab's issue.
#
# @param string $1 issue number
#

ref="$1"
project_addr=$(git config --get remote.$TWGIT_ORIGIN.url)

gitlat_attribute="ssh_url_to_repo"

if [[ $project_addr == *"https://"* ]]; then
    gitlat_attribute="http_url_to_repo"
fi

if [[ "$TWGIT_FEATURE_SUBJECT_GITLAB_DOMAIN" =~ ^https?:// ]]; then
    scheme=''
else
    scheme='https://'
fi

project_url="$scheme$TWGIT_FEATURE_SUBJECT_GITLAB_DOMAIN/api/v4/projects?private_token=$TWGIT_FEATURE_SUBJECT_GITLAB_API_KEY"
issue_url="$scheme$TWGIT_FEATURE_SUBJECT_GITLAB_DOMAIN/api/v4/projects/%s/issues?private_token=$TWGIT_FEATURE_SUBJECT_GITLAB_API_KEY"
if ${has_wget}; then
    cmd="wget --no-check-certificate --timeout=3 -q -O - --no-cache"
else
    cmd="curl --insecure --max-time 3 --silent -H \"Cache-control: no-cache\""
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

    if [[ "$ref" =~ ^[0-9]+$ ]]; then
        ($cmd $project_url \
        | python -c 'import sys,json,urllib;s=sys.stdin.read();
data=json.loads(s) if s!="" else sys.exit(0)
projectId=None
for row in data:
    if row["'$gitlat_attribute'"] == "'$project_addr'" :
        projectId = row["id"]; break;
f = urllib.urlopen("'$issue_url'" % (projectId))
s = f.read()
data=json.loads(s) if s!="" else sys.exit(0);
for row in data:
    if row["iid"] == '$ref' :
        print row["title"].encode("utf8"); break;')
        2>/dev/null
    fi
elif [ "$language" = 'php' ]; then

    if [[ "$ref" =~ ^[0-9]+$ ]]; then
        ($cmd $project_url \
        | php -r '$o = json_decode(file_get_contents("php://stdin"));$projectid=array_reduce($o, function($carry, $item){if($carry==null && $item->'$gitlat_attribute' == "'$project_addr'"){return
$item->id;}return $carry;}, null);$o=json_decode(file_get_contents(sprintf("'$issue_url'", $projectid,'$ref')));if ($o !== NULL) {array_walk($o, function($item,
$key){if($item->iid == '$ref'){print_r($item->title);}});}')
        2>/dev/null
    fi
else
    echo "Language '$language' not handled!" >&2
    exit 1
fi
