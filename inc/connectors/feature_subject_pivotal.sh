#!/bin/bash

##
# twgit
#
#
#
# Copyright (c) 2017 Alexandre Guidet <guidet.alexandre@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#

##
# Retrieve and display subject of a Pivotal's story.
#
# @param string $1 story number
#
issue="$1"
url="$(printf "%s/projects/%s/stories/%s" \
        "https://www.pivotaltracker.com/services/v5" \
        "$TWGIT_FEATURE_SUBJECT_PIVOTAL_PROJECT_ID" \
        "$issue")"

cmd="curl -X GET -H \"X-TrackerToken: ${TWGIT_FEATURE_SUBJECT_PIVOTAL_API_TOKEN}\" ${url}"

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
        echo $data | python -c "import json,sys;s=sys.stdin.read();s=s.replace('\r\n', '');s=json.loads(s);print s['name'].encode('utf8');" 2>/dev/null
    fi
elif [ "$language" = 'php' ]; then
    if [ ! -z "$data" ]; then
        echo $data | php -r '$o = json_decode(file_get_contents("php://stdin")); echo $o->name;' 2>/dev/null
    fi
else
    echo "Language '$language' not handled!" >&2
    exit 1
fi

exit 0
