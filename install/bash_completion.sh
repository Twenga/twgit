#!/usr/bin/env bash

##
# Bash completion support for twgit.
# Dest path: /etc/bash_completion.d/twgit
# Install: sudo make install
#
#
#
# Copyright (c) 2011 Twenga SA
# Copyright (c) 2012-2013 Geoffroy Aubry <geoffroy.aubry@free.fr>
# Copyright (c) 2013 Cyrille Hemidy
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
# @copyright 2011 Twenga SA
# @copyright 2012-2013 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @copyright 2013 Cyrille Hemidy
# @copyright 2014 Laurent Toussaint <lt.laurent.toussaint@gmail.com>
# @license http://www.apache.org/licenses/LICENSE-2.0
#



function _twgit () {
    COMPREPLY=()
    local cur="${COMP_WORDS[COMP_CWORD]}"

    if [ "$COMP_CWORD" = "1" ]; then
        local opts="clean feature demo help init hotfix release tag update"
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )

    elif [ "$COMP_CWORD" = "2" ]; then
        local command="${COMP_WORDS[COMP_CWORD-1]}"
        case "${command}" in
            feature)
                local opts="committers help list merge-into-release merge-into-hotfix migrate push remove start startFrom status what-changed"
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                ;;
            demo)
                local opts="help list merge-feature update-features merge-demo push remove start status"
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                ;;
            hotfix)
                local opts="finish help list push remove start"
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                ;;
            release)
                local opts="committers finish merge-demo help list push remove reset start"
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                ;;
            tag)
                local opts="help list"
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                ;;
        esac

    elif [ "$COMP_CWORD" -gt "2" ]; then
        local command="${COMP_WORDS[1]}"
        local action="${COMP_WORDS[2]}"
        case "${command}" in
            feature)
                case "${action}" in
                    committers)
                         if [[ ${cur} != -* ]] ; then
                            local opts=$((git branch --no-color -r | grep "feature-" | sed 's/^[* ]*//' | sed 's#^origin/feature-##' | tr '\n' ' ') 2>/dev/null)
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        else
                            local opts="-F"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                    list)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-F -c -x"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                    start)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-d"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                esac
                ;;

            demo)
                case "${action}" in
                    list)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-F -c"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                    start)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-d"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                esac
                ;;

            hotfix)
                case "${action}" in
                    xxxxxxx)
                         if [[ ${cur} != -* ]] ; then
                            local opts=$((git branch --no-color -r | grep "hotfix-" | sed 's/^[* ]*//' | sed 's#^origin/hotfix-##' | tr '\n' ' ') 2>/dev/null)
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                        finish)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-I"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                    list)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-F"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                esac
                ;;

            release)
                case "${action}" in
                    committers)
                         if [[ ${cur} == -* ]] ; then
                            local opts="-F"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                    finish)
                         if [[ ${cur} != -* ]] ; then
                            local opts=$((git branch --no-color -r | grep "release-" | sed 's/^[* ]*//' | sed 's#^origin/release-##' | tr '\n' ' ') 2>/dev/null)
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        else
                            local opts="-I"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                    list)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-F"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                    start)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-I -M -m"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                esac
                ;;
        esac
    fi
}

complete -F _twgit twgit
