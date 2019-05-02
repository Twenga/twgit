#!/bin/bash

##
# twgit
#
#
#
# Copyright (c) 2019 Alexandre Guidet <guidet.alexandre@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#

##
# variables:
#
# TWGIT_FEATURE_SUBJECT_CONNECTOR='gitlab_api_v4'
# TWGIT_FEATURE_SUBJECT_GITLAB_DOMAIN="https://gitlab.mycompany.com"
# TWGIT_FEATURE_SUBJECT_GITLAB_PROJECT_ID="123456"
# TWGIT_FEATURE_SUBJECT_GITLAB_TOKEN="abcdxyz"

##
# Retrieve and display subject of a Gitlab api v4's story.
#
# @param string $1 story number
#
issue="$1"
url="$(printf "%s/api/v4/projects/%s/issues/%s?private_token=%s" \
        "$TWGIT_FEATURE_SUBJECT_GITLAB_DOMAIN" \
        "$TWGIT_FEATURE_SUBJECT_GITLAB_PROJECT_ID" \
        "$issue" \
        "$TWGIT_FEATURE_SUBJECT_GITLAB_TOKEN")"

cmd="curl --insecure --max-time 3 --silent -H \"Cache-control: no-cache\" ${url}"

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
    if [ ! -z "$data" ]; then
        echo $data | python -c "import json,sys;s=sys.stdin.read();s=s.replace('\r\n', '');s=json.loads(s);print s['title'].encode('utf8');" 2>/dev/null
    fi
elif [ "$language" = 'php' ]; then
    if [ ! -z "$data" ]; then
        echo $data | php -r '$o = json_decode(file_get_contents("php://stdin")); echo $o->title;' 2>/dev/null
    fi
else
    echo "Language '$language' not handled!" >&2
    exit 1
fi

exit 0
