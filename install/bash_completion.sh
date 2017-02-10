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
        local opts="clean demo feature help hotfix init release tag update"
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )

    elif [ "$COMP_CWORD" = "2" ]; then
        local command="${COMP_WORDS[COMP_CWORD-1]}"
        case "${command}" in
            feature)
                local opts="committers help list merge-into-hotfix merge-into-release migrate push remove start status what-changed"
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                ;;
            demo)
                local opts="help list merge-demo merge-feature push remove start status update-features"
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                ;;
            hotfix)
                local opts="finish help list push remove start"
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                ;;
            release)
                local opts="committers finish help list merge-demo push remove reset start"
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                ;;
            tag)
                local opts="help list"
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                ;;
        esac

    elif [ "$COMP_CWORD" -gt "2" ]; then

        local words=( $(echo ${COMP_WORDS[@]} | sed 's/ -[a-zA-Z-]*//g' | sed "s/ ${cur}$//") )
        local previous="${words[-1]}"
        local command="${COMP_WORDS[1]}"
        local action="${COMP_WORDS[2]}"
        local features="$( (git branch --no-color -r | grep 'feature-' | sed 's#^[* ]*origin/feature-##' | tr '\n' ' ') 2>/dev/null)"
        local demos="$( (git branch --no-color -r | grep 'demo-' | sed 's#^[* ]*origin/demo-##' | tr '\n' ' ') 2>/dev/null)"

        case "${command}" in
            feature)
                case "${action}" in
                    committers)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-F"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        elif [[ "${previous}" == "${action}" ]] ; then
                            COMPREPLY=( $(compgen -W "${features}" -- ${cur}) )
                        fi
                        ;;
                    list)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-F -c -x"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                    merge-into-release|merge-into-hotfix|remove|status|what-changed)
                        if [[ "${previous}" == "${action}" ]] ; then
                            COMPREPLY=( $(compgen -W "${features}" -- ${cur}) )
                        fi
                        ;;
                    migrate)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-I"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        elif [[ "${previous}" == "${action}" ]] ; then
                            local branches="$( (git branch --no-color -r | grep -vE 'origin/(feature-|demo-|release-|hotfix-|HEAD |stable$|master$)' | sed 's#^[* ]*origin/##' | tr '\n' ' ') 2>/dev/null)"
                            COMPREPLY=( $(compgen -W "${branches}" -- ${cur}) )
                        fi
                        ;;
                    start)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-d"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        else
                            case "${previous}" in
                                start|from-feature)
                                    COMPREPLY=( $(compgen -W "${features}" -- ${cur}) )
                                    ;;
                                from-demo)
                                    COMPREPLY=( $(compgen -W "${demos}" -- ${cur}) )
                                    ;;
                                *)
                                    if [[ ${words[-2]} == "${action}" && " ${features} " != *" ${previous} "* ]] ; then
                                        local opts="from-demo from-feature from-release"
                                        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                                    fi
                                    ;;
                            esac
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
                        elif [[ "${previous}" == "${action}" ]] ; then
                            COMPREPLY=( $(compgen -W "${demos}" -- ${cur}) )
                        fi
                        ;;
                    merge-demo|remove|status)
                        if [[ "${previous}" == "${action}" ]] ; then
                            COMPREPLY=( $(compgen -W "${demos}" -- ${cur}) )
                        fi
                        ;;
                    merge-feature)
                        if [[ "${previous}" == "${action}" ]] ; then
                            COMPREPLY=( $(compgen -W "${features}" -- ${cur}) )
                        fi
                        ;;
                    start)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-d"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        else
                            case "${previous}" in
                                start|from-demo)
                                    COMPREPLY=( $(compgen -W "${demos}" -- ${cur}) )
                                ;;
                                *)
                                    if [[ ${words[-2]} == "${action}" && " ${demos} " != *" ${previous} "* ]] ; then
                                        local opts="from-demo from-release"
                                        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                                    fi
                                    ;;
                            esac
                        fi
                        ;;
                esac
                ;;

            hotfix)
                local hotfixes="$( (git branch --no-color -r | grep 'hotfix-' | sed 's#^[* ]*origin/hotfix-##' | tr '\n' ' ') 2>/dev/null)"
                case "${action}" in
                    finish|start)
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
                    remove)
                        if [[ "${previous}" == "${action}" ]] ; then
                            COMPREPLY=( $(compgen -W "${hotfixes}" -- ${cur}) )
                        fi
                        ;;
                esac
                ;;

            release)
                local releases="$( (git branch --no-color -r | grep 'release-' | sed 's#^[* ]*origin/release-##' | tr '\n' ' ') 2>/dev/null)"
                case "${action}" in
                    committers)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-F"
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
                    merge-demo)
                        if [[ "${previous}" == "${action}" ]] ; then
                            COMPREPLY=( $(compgen -W "${demos}" -- ${cur}) )
                        fi
                        ;;
                    remove)
                        if [[ "${previous}" == "${action}" ]] ; then
                            COMPREPLY=( $(compgen -W "${releases}" -- ${cur}) )
                        fi
                        ;;
                    reset)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-I -M -m"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        elif [[ "${previous}" == "${action}" ]] ; then
                            COMPREPLY=( $(compgen -W "${releases}" -- ${cur}) )
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

            tag)
                case "${action}" in
                    list)
                        if [[ ${cur} == -* ]] ; then
                            local opts="-F"
                            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
                        fi
                        ;;
                esac
                ;;
        esac
    fi
}

complete -F _twgit twgit
