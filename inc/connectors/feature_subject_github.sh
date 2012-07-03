#!/bin/bash

##
# twgit
#
#
#
# Copyright (c) 2011 Twenga SA
# Copyright (c) 2012 Geoffroy Aubry <geoffroy.aubry@free.fr>
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
# @copyright 2012 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @license http://www.apache.org/licenses/LICENSE-2.0
#



##
# Retrive and display subject of a Github's issue.
# Compatible Github API v3: http://developer.github.com/v3/.
#
# @param string $1 issue name
#
issue="$1"
url="$(printf "https://api.github.com/repos/%s/%s/issues/%s" \
        "$TWGIT_FEATURE_SUBJECT_GITHUB_USER" \
        "$TWGIT_FEATURE_SUBJECT_GITHUB_REPOSITORY" \
        "$issue")"
(wget --no-check-certificate --timeout=2 -q -O - --no-cache $url \
    | php -r '$o = json_decode(file_get_contents("php://stdin")); if ($o !== NULL) {print_r($o->title);}')
    2>/dev/null