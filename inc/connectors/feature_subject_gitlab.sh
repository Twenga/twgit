#!/usr/bin/env bash

##
# twgit
#
#
#
# Copyright (c) 2014 Karl Marques <marques.karl@live.fr>
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
# @license http://www.apache.org/licenses/LICENSE-2.0
#

##
# Retrieve and display subject of a Gitlab's issue.
#
# @param string $1 issue number
#
ref="$1"
project_addr=$(git remote show -n $TWGIT_ORIGIN | grep Fetch | cut -d: -f3 | cut -d. -f1)

if [[ "$TWGIT_FEATURE_SUBJECT_GITLAB_DOMAIN" =~ ^https?:// ]]; then
    scheme=''
else
    scheme='https://'
fi

project_url="$scheme$TWGIT_FEATURE_SUBJECT_GITLAB_DOMAIN/api/v3/projects/all?private_token=$TWGIT_FEATURE_SUBJECT_GITLAB_API_KEY"
issue_url="$scheme$TWGIT_FEATURE_SUBJECT_GITLAB_DOMAIN/api/v3/projects/%s/issues?private_token=$TWGIT_FEATURE_SUBJECT_GITLAB_API_KEY"
wget_cmd='wget --no-check-certificate --timeout=3 -q -O - --no-cache'

# Python or PHP ?
language='?'
which php 1>/dev/null 2>&1
if [ $? -eq 0 ]; then
   language='php'
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
        ($wget_cmd $project_url \
        | php -r '$o = json_decode(file_get_contents("php://stdin"));$projectid=array_reduce($o, function($carry, $item){if($carry==null && $item->path_with_namespace == "'$project_addr'"){return 
$item->id;}return $carry;}, null);$o=json_decode(file_get_contents(sprintf("'$issue_url'", $projectid,'$ref')));if ($o !== NULL) {array_walk($o, function($item, 
$key){if($item->iid == '$ref'){print_r($item->title);}});}')
		2>/dev/null
    else
        ($wget_cmd $project_url \
        | php -r '$o = json_decode(file_get_contents("php://stdin"));array_walk($o, function($item, $key){if($item->path_with_namespace == "'$ref'"){print_r($item->name);}});')
		2>/dev/null
    fi
else
    echo "Language '$language' not handled!" >&2
    exit 1
fi
