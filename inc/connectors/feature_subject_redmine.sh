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
# Retrive and display subject of a Redmine's issue.
#
# @param string $1 issue number or project name
#
ref="$1"
issue_url="https://$TWGIT_FEATURE_SUBJECT_REDMINE_DOMAIN/issues/$ref.json?key=$TWGIT_FEATURE_SUBJECT_REDMINE_API_KEY"
project_url="https://$TWGIT_FEATURE_SUBJECT_REDMINE_DOMAIN/projects/$ref.json?key=$TWGIT_FEATURE_SUBJECT_REDMINE_API_KEY"

if [[ "$ref" =~ ^[0-9]+$ ]]; then
    (wget -q -O - --no-cache $issue_url \
    | php -r '$o = json_decode(file_get_contents("php://stdin")); if ($o !== NULL) {print_r($o->issue->subject);}')
    2>/dev/null
else
    (wget -q -O - --no-cache $project_url \
    | php -r '$o = json_decode(file_get_contents("php://stdin")); if ($o !== NULL) {print_r($o->project->name);}')
    2>/dev/null
fi
