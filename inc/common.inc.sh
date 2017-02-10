#!/usr/bin/env bash

##
# twgit
#
#
#
# Copyright (c) 2011 Twenga SA
# Copyright (c) 2012-2013 Geoffroy Aubry <geoffroy.aubry@free.fr>
# Copyright (c) 2012-2014 Laurent Toussaint <lt.laurent.toussaint@gmail.com>
# Copyright (c) 2013 Cyrille Hemidy
# Copyright (c) 2013 Geoffroy Letournel <gletournel@hi-media.com>
# Copyright (c) 2013 Sebastien Hanicotte <shanicotte@hi-media.com>
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
# @copyright 2012 Jérémie Havret <jhavret@hi-media.com>
# @copyright 2012-2014 Laurent Toussaint <lt.laurent.toussaint@gmail.com>
# @copyright 2013 Cyrille Hemidy
# @copyright 2013 Geoffroy Letournel <gletournel@hi-media.com>
# @copyright 2013 Sebastien Hanicotte <shanicotte@hi-media.com>
# @license http://www.apache.org/licenses/LICENSE-2.0
#



. $TWGIT_INC_DIR/options_handler.inc.sh
. $TWGIT_INC_DIR/coloredUI.inc.sh
. $TWGIT_INC_DIR/compatibility.inc.sh
. $TWGIT_INC_DIR/dyslexia.inc.sh



#--------------------------------------------------------------------
# Functions "Get"
#--------------------------------------------------------------------

##
# Affiche les $1 derniers hotfixes (nom complet), à raison d'un par ligne.
#
# @param int $1 nombre des derniers hotfixes à afficher
#
function get_last_hotfixes () {
    git branch --no-color -r | grep $TWGIT_ORIGIN/$TWGIT_PREFIX_HOTFIX | sed 's/^[* ] //' | sort -n | tail -n $1
}

##
# Affiche les branches locales (nom complet), à raison d'une par ligne.
#
function get_local_branches () {
    git branch --no-color | sed 's/^[* ] //'
}

##
# Affiche la liste locale des branches distantes (nom complet), à raison d'une par ligne.
#
function get_remote_branches () {
    git branch --no-color -r | sed 's/^[* ] //'
}

##
# Affiche la liste des branches distantes qui ne sont pas catégorisables dans le process.
#
# @testedby TwgitCommonGettersTest
#
function get_dissident_remote_branches () {
    # génère une chaîne du genre : ' -e "^second/" -e "^third/"'
    local cmd="$(git remote | grep -v "^$TWGIT_ORIGIN$" | sed -e 's/^/ -e "^/' -e 's/$/\/"/' | tr '\n' ' ')"

    [ -z "$cmd" ] && cmd='tee /dev/null' || cmd="grep -v $cmd"
    git branch --no-color -r | sed 's/^[* ] //' | sed -e 's/^/ /' -e 's/$/ /' \
        | grep -v -e " $TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" \
            -e " $TWGIT_ORIGIN/$TWGIT_PREFIX_RELEASE" \
            -e " $TWGIT_ORIGIN/$TWGIT_PREFIX_HOTFIX" \
            -e " $TWGIT_ORIGIN/$TWGIT_PREFIX_DEMO" \
            -e " $TWGIT_ORIGIN/HEAD " \
            -e " $TWGIT_ORIGIN/master " \
            -e " $TWGIT_ORIGIN/$TWGIT_STABLE " \
        | sed 's/[ ]//' \
        | eval "$cmd" \
        || :
}

##
# Affiche le nom complet des releases distantes (avec "$TWGIT_ORIGIN/") non encore mergées à $TWGIT_ORIGIN/$TWGIT_STABLE, à raison d'une par ligne.
#
function get_releases_in_progress () {
    git branch --no-color -r --no-merged $TWGIT_ORIGIN/$TWGIT_STABLE \
        | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_RELEASE" | sed 's/^[* ]*//'
}

##
# Affiche le nom complet des releases non encore mergées à $TWGIT_ORIGIN/$TWGIT_STABLE, à raison d'une par ligne.
#
function get_hotfixes_in_progress () {
    git branch --no-color -r --no-merged $TWGIT_ORIGIN/$TWGIT_STABLE \
        | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_HOTFIX" | sed 's/^[* ]*//'
}

##
# Affiche la release distante courante (nom complet sans "$TWGIT_ORIGIN/"),
# c.-à-d. celle normalement unique à ne pas avoir été encore mergée à $TWGIT_ORIGIN/$TWGIT_STABLE.
# Chaîne vide sinon.
#
function get_current_release_in_progress () {
    local releases="$(get_releases_in_progress)"
    local release="$(echo $releases | tr '\n' ' ' | cut -d' ' -f1)"
    [[ $(echo $releases | wc -w) > 1 ]] && die "More than one release in progress detected: $(echo $releases | sed 's/ /, /g')! Only '$release' will be treated here."
    echo ${release:((${#TWGIT_ORIGIN}+1))}	# delete 'origin/' prefix
}

function get_current_hotfix_in_progress () {
    local hotfixes="$(get_hotfixes_in_progress)"
    local hotfix="$(echo $hotfixes | tr '\n' ' ' | cut -d' ' -f1)"
    [[ $(echo $hotfixes | wc -w) > 1 ]] && die "More than one hotfix in progress detected: $(echo $hotfixes | sed 's/ /, /g')! Only '$hotfix' will be treated here."
    echo ${hotfix:((${#TWGIT_ORIGIN}+1))}	# delete 'origin/' prefix
}

##
# Calcule la liste locale des features distantes (nom complet avec "$TWGIT_ORIGIN/") mergées à la release distante $1,
# sur une seule ligne séparées par des espaces,
# et enregistre le résultat dans la globale GET_MERGED_FEATURES_RETURN_VALUE afin d'éviter les subshells.
#
# @param string $1 nom complet d'une release distante, sans "$TWGIT_ORIGIN/"
# @testedby TwgitFeatureClassificationTest
#
function get_merged_features () {
    local release="$1"

    get_git_merged_branches $TWGIT_ORIGIN/$release
    local merged_branches="${MERGED_BRANCHES[$TWGIT_ORIGIN/$release]}"

    local features="$(echo "$merged_branches" | grep $TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE | sort --field-separator="-" -k1rn -k2rn | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g')"

    get_features merged $release
    local features_v2="$GET_FEATURES_RETURN_VALUE"

    [ "$features" != "$features_v2" ] && die "Inconsistent result about merged features: '<b>$features</b>' != '<b>$features_v2</b>'!"
    GET_MERGED_FEATURES_RETURN_VALUE="$features"
}

##
# Tableau associatif de mise en cache des appels à git rev-parse.
#
# @var array tableau associatif
# @see get_git_rev_parse()
#
declare -A REV_PARSE

##
# Calcule si non déjà fait le git rev-parse de la branche spécifiée
# et met en cache le résultat dans la globale REV_PARSE.
#
# Ex. :
#     branch='feature-123'
#     get_git_rev_parse "$branch"
#     rev="${REV_PARSE[$branch]}"
#
# @param string $1 nom complet d'une branche
# @see REV_PARSE
# @testedby TwgitFeatureClassificationTest
#
function get_git_rev_parse () {
    local key="$1"
    if [ ! -z "$key" ] && [ -z "${REV_PARSE[$key]}" ]; then
        REV_PARSE[$key]="$(git rev-parse --verify -q "$key")"
    fi
}

##
# Tableau associatif de mise en cache des appels à git merge-base.
#
# @var array tableau associatif
# @see get_git_merge_base()
#
declare -A MERGE_BASE

##
# Calcule si non déjà fait le git merge-base des 2 références (SHA1) spécifiées
# et met en cache le résultat dans la globale MERGE_BASE.
#
# La clé de cache est "$1|$2".
#
# Ex. :
#     rev1='fafc000ac57ef285f7de7326c6cf8859ffd36996'
#     rev2='e7326c6cf57ef285f7d8859ffd36996fafc000ac'
#     get_git_merge_base "$rev1" "$rev2"
#     result="${MERGE_BASE[$rev1|$rev2]}"
#
# @param string $1 référence (SHA1) git
# @param string $2 référence (SHA1) git
# @param string $3 si 1 alors considérer tous les merge-base potentiels et ne garder que le premier
#     de ceux appartenant aux first-parents (la branche source) de $2
#     cf. TwgitFeatureClassificationTest::testGetFeatures_WithLastTagMergedIntoFeature()
# @see MERGE_BASE
# @testedby TwgitFeatureClassificationTest
#
function get_git_merge_base () {
    local rev1="$1"
    local rev2="$2"
    local forced="$3"
    local key="$rev1|$rev2"
    if [ "$key" != '|' ] && [ -z "${MERGE_BASE[$key]}" ]; then
        if [ "$forced" = '1' ]; then
            MERGE_BASE[$key]="$( \
                (git rev-list --first-parent $rev2; git merge-base --all $rev1 $rev2 2>/dev/null) \
                | sort | uniq -d | head -n1 \
            )"
        else
            MERGE_BASE[$key]="$(git merge-base $rev1 $rev2 2>/dev/null)"
        fi
    fi
}

##
# Tableau associatif de mise en cache des appels (très coûteux) à git branch -r --merged.
#
# @var array tableau associatif
# @see get_git_merged_branches()
#
declare -A MERGED_BRANCHES

##
# Calcule si non déjà fait le git branch -r --merged de la branche spécifiée
# et met en cache le résultat dans la globale MERGED_BRANCHES.
#
# Ex. :
#     branch='release-1.2.3'
#     get_git_merged_branches "$branch"
#     merged_branches="${MERGED_BRANCHES[$branch]}"
#
# @param string $1 nom complet d'une branche
# @see MERGED_BRANCHES
# @testedby TwgitFeatureClassificationTest
#
function get_git_merged_branches () {
    local rev="$1"
    if [ ! -z "$rev" ] && [ -z "${MERGED_BRANCHES[$rev]}" ]; then
        MERGED_BRANCHES[$rev]="$(git branch --no-color -r --merged $rev 2>/dev/null)"
    fi
}

##
# Calcule la liste des features (nom complet) de relation de type $1 avec la release distante $2,
# sur une seule ligne séparées par des espaces, et enregistre le résultat dans la globale GET_FEATURES_RETURN_VALUE
# afin d'éviter les subshells.
#
# Ex. :
#     get_features merged $release
#     features="$GET_FEATURES_RETURN_VALUE"
#
# @param string $1 Type de relation avec la release $2 :
#    - 'merged' pour lister les features mergées dans la release $2 et restées telle quelle depuis.
#    - 'merged_in_progress' pour lister les features mergées dans la release $2 et dont le développement à continué.
#    - 'free' pour lister celles n'ayant aucun rapport avec la release $2
# @param string $2 nom complet d'une release distante, sans "$TWGIT_ORIGIN/"
# @testedby TwgitFeatureClassificationTest
#
function get_features () {
    local feature_type="$1"
    local release="$2"

    if [ -z "$release" ]; then
        if [ "$feature_type" = 'free' ]; then
            GET_FEATURES_RETURN_VALUE="$(git branch --no-color -r --no-merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sort --field-separator="-" -k1rn -k2rn | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g')"
        else
            GET_FEATURES_RETURN_VALUE=''
        fi
    else
        release="$TWGIT_ORIGIN/$release"
        local return_features=''

        local features=$(git branch --no-color -r | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sort --field-separator="-" -k1rn -k2rn | sed 's/^[* ]*//')

        get_git_rev_parse "$TWGIT_ORIGIN/$TWGIT_STABLE"
        local head_rev="${REV_PARSE[$TWGIT_ORIGIN/$TWGIT_STABLE]}"

        get_git_rev_parse $release
        local release_rev="${REV_PARSE[$release]}"

        local f_rev release_merge_base stable_merge_base check_merge has_dependency

        get_git_merged_branches $release
        local merged_branches="${MERGED_BRANCHES[$release]}"

        for f in $features; do
            get_git_rev_parse $f
            f_rev="${REV_PARSE[$f]}"

            get_git_merge_base $release_rev $f_rev 1
            release_merge_base="${MERGE_BASE[$release_rev|$f_rev]}"

            if [ "$release_merge_base" = "$f_rev" ] && [ -n "$(echo "$merged_branches" | grep $f)" ]; then
                [ "$feature_type" = 'merged' ] && return_features="$return_features $f"
            else
                get_git_merge_base $release_merge_base $head_rev
                stable_merge_base="${MERGE_BASE[$release_merge_base|$head_rev]}"

                if [ "$release_merge_base" != "$stable_merge_base" ] && \
                        [ "$(git rev-list $f_rev ^$release_merge_base ^$stable_merge_base --parents --first-parent | cut -d' ' -f2 | grep $release_merge_base | wc -l)" -eq 1 ]; then
                    [ "$feature_type" = 'merged_in_progress' ] && return_features="$return_features $f"
                elif [ "$feature_type" = 'free' ]; then
                    return_features="$return_features $f"
                fi
            fi
        done

        GET_FEATURES_RETURN_VALUE="${return_features:1}"
    fi
}

##
# Récupère la liste des demos, sur une seule ligne séparées par des espaces.
#
# Ex. :
#     get_all_demos
#     demos="$RETVAL"
#
function get_all_demos () {
    RETVAL="$(git branch --no-color -r --no-merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_DEMO" | sort --field-separator="-" -k1rn -k2rn | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g')"
}


##
# Affiche le nom complet de la branche courante, chaîne vide sinon.
#
function get_current_branch () {
    git branch --no-color | grep '^\* ' | grep -v 'no branch' | sed 's/^* //g'
}

##
# Affiche la liste des tags gérés par le workflow (nom complet) triés par ordre croissant, à raison d'un par ligne.
#
# @param int $1 si renseigné alors limite la liste aux $1 derniers tags
#
function get_all_tags () {
    local n="$1"
    [ -z "$n" ] && n=10000	# pour tout retourner
    git tag | grep -E '^'$TWGIT_PREFIX_TAG'[0-9]+\.[0-9]+\.[0-9]+$' | sed "s/$TWGIT_PREFIX_TAG//" | sed 's/\./;/g' \
        | sort --field-separator=";" -k1n -k2n -k3n | sed 's/;/./g' | tail -n $n | sed "s/^/$TWGIT_PREFIX_TAG/"
}

##
# Affiche le nom complet du tag le plus récent.
#
function get_last_tag () {
    get_all_tags 1
}

##
# Concatène le nom complet de tous les tags réalisés depuis la création de la branche $1 (via hotfixes ou releases)
# et qui n'y sont pas mergés, sur une seule ligne, séparés par des espaces,
# et enregistre le résultat dans la globale GET_TAGS_NOT_MERGED_INTO_BRANCH_RETURN_VALUE afin d'éviter les subshells.
#
# Par de l'hypothèse que si un tag est mergé dans une branche, alors tous les tags plus anciens le sont également.
#
# @param string $1 nom complet de la branche, locale ou distante
#
function get_tags_not_merged_into_branch () {
    get_git_rev_parse "$1"
    local release_rev="${REV_PARSE[$1]}"

    local tag_rev merge_base
    local tags_not_merged=''
    local inverted_tags_not_merged=''

    local all_tags="$(get_all_tags)"
    local inverted_all_tags
    for t in $all_tags; do
        inverted_all_tags="$t $inverted_all_tags"
    done

    local max_tags=$TWGIT_MAX_RETRIEVE_TAGS_NOT_MERGED
    for t in $inverted_all_tags; do
        tag_rev=$(git rev-list tags/$t | head -n 1)
        merge_base=$(git merge-base $release_rev $tag_rev)
        if [ "$tag_rev" != "$merge_base" ]; then
            inverted_tags_not_merged="$inverted_tags_not_merged $t"
            let max_tags--
            [ "$max_tags" -eq 0 ] && break
        else
            break
        fi
    done

    for t in $inverted_tags_not_merged; do
        tags_not_merged="$t $tags_not_merged"
    done
    GET_TAGS_NOT_MERGED_INTO_BRANCH_RETURN_VALUE="${tags_not_merged% }"
}

##
# Affiche le prochain numéro de version suivant le type d'évolution spécifié.
# Une version est du type [major].[minor].[revision].
#
# @param string $1 type d'évolution : 'major', 'minor' ou 'revision'
#
function get_next_version () {
    local change_type="$1"
    local last_tag=$(get_last_tag)
    local current_version=${last_tag:${#TWGIT_PREFIX_TAG}}

    local major=$(echo $current_version | cut -d. -f1)
    local minor=$(echo $current_version | cut -d. -f2)
    local revision=$(echo $current_version | cut -d. -f3)

    case "$change_type" in
        major) let major++; minor=0; revision=0 ;;
        minor) let minor++; revision=0 ;;
        revision) let revision++ ;;
        *) die "Invalid version change type: '$change_type'!" ;;
    esac
    echo "$major.$minor.$revision"
}

##
# Calcul et retourne la liste des emails des N auteurs de commit les plus significatifs (en nombre de commits)
# de la branche distante spécifiée, à raison d'un par ligne.
# Filtre les auteurs sans email ainsi que ceux en dehors du domaine '@$TWGIT_EMAIL_DOMAIN_NAME' si défini.
#
# @param string $1 nom complet de branche distante, sans le "$TWGIT_ORIGIN/"
# @param int $2 nombre maximum d'auteurs à afficher
# @see display_rank_contributors()
# @testedby TwgitMainTest
#
function get_contributors () {
    local branch="$TWGIT_ORIGIN/$1"
    local max="$2"
    local domain_pattern

    [ -z "$TWGIT_EMAIL_DOMAIN_NAME" ] && domain_pattern='.*' || domain_pattern="$TWGIT_EMAIL_DOMAIN_NAME"
    git shortlog -nse $TWGIT_ORIGIN/$TWGIT_STABLE..$branch \
        | grep -E "@$domain_pattern>$" \
        | head -n $max | tr -s '\t' ' ' | cut -d' ' -f3-
}

##
# Affiche le sujet d'une feature (sans aucune coloration) en le récupérant
# d'une plate-forme Redmine, Github ou autre via le connecteur défini
# par TWGIT_FEATURE_SUBJECT_CONNECTOR.
#
# Le premier appel sollicite le connecteur concerné,
# les suivants bénéficieront du fichier de cache $TWGIT_FEATURES_SUBJECT_PATH.
#
# Le fichier associé au connecteur est défini par $TWGIT_FEATURE_SUBJECT_CONNECTOR_PATH.
#
# @param int $1 nom court de la feature
# @testedby TwgitCommonGettersTest
#
function getFeatureSubject () {
    local short_name="$1"
    local subject

    [ ! -s "$TWGIT_FEATURES_SUBJECT_PATH" ] && touch "$TWGIT_FEATURES_SUBJECT_PATH"

    subject="$(cat "$TWGIT_FEATURES_SUBJECT_PATH" | grep -E "^$short_name;" | head -n 1 | sed 's/^[^;]*;//')"
    if [ ! -z "$short_name" ] && [ -z "$subject" ] && [ ! -z "$TWGIT_FEATURE_SUBJECT_CONNECTOR" ]; then
        local connector="$(printf "$TWGIT_FEATURE_SUBJECT_CONNECTOR_PATH" "$TWGIT_FEATURE_SUBJECT_CONNECTOR")"
        if [ -f "$connector" ]; then
            subject="$(. $connector $short_name 2>/dev/null)"
            if [ $? -ne 0 ]; then
                CUI_displayMsg error "'$TWGIT_FEATURE_SUBJECT_CONNECTOR' connector failed!"
            elif [ ! -z "$subject" ]; then
                echo "$short_name;$subject" >> "$TWGIT_FEATURES_SUBJECT_PATH"
            fi
        fi
    fi

    echo $subject
}



#--------------------------------------------------------------------
# Assertions
#--------------------------------------------------------------------

##
# S'assure que le client git a bien ses globales user.name et user.email de configurées.
#
# @testedby TwgitSetupTest
#
function assert_git_configured () {
    if [ -z "$(git config user.name 2>/dev/null | tr -d ' ')" ]; then
        die "Unknown user.name! Please, do: git config --global user.name 'Firstname Lastname'"
    elif [ -z "$(git config user.email 2>/dev/null | tr -d ' ')" ]; then
        die "Unknown user.email! Please, do: git config --global user.email 'firstname.lastname@xyz.com'"
    fi
}

##
# S'assure que si un connecteur pour le sujet des features est déclaré, alors il est connu et wget est installé.
#
# @testedby TwgitSetupTest
#
function assert_connectors_well_configured () {
    if [ ! -z "$TWGIT_FEATURE_SUBJECT_CONNECTOR" ]; then
        local connector="$(printf "$TWGIT_FEATURE_SUBJECT_CONNECTOR_PATH" "$TWGIT_FEATURE_SUBJECT_CONNECTOR")"
        if [ ! -f "$connector" ]; then
            die "'<b>$TWGIT_FEATURE_SUBJECT_CONNECTOR</b>' connector not found!" \
                "Please adjust <b>TWGIT_FEATURE_SUBJECT_CONNECTOR</b> in '$config_file'."
        elif ! ${has_wget} && ! ${has_curl} ; then
            die "Feature's subject not available because <b>wget</b> or <b>curl</b> was not found!" \
                "Install wget (e.g.: apt-get install wget) or curl (e.g.: apt-get install curl) or switch off connectors in '$config_file'."
        fi
    fi
}

##
# S'assure que l'utilisateur se trouve dans un dépôt git et que celui-ci possède une branche stable et au moins un tag.
#
# @testedby TwgitSetupTest
#
function assert_git_repository () {
    local errormsg=$(git rev-parse --git-dir 2>&1 1>/dev/null)
    [ ! -z "$errormsg" ] && die "[Git error msg] $errormsg"

    assert_recent_git_version "$TWGIT_GIT_MIN_VERSION"

    if [ "$(git remote | grep -E "^$TWGIT_ORIGIN$" | wc -l)" -ne 1 ]; then
        die "No remote '<b>$TWGIT_ORIGIN</b>' repository specified! Try: git remote add $TWGIT_ORIGIN <url>"
    fi

    local stable="$TWGIT_ORIGIN/$TWGIT_STABLE"
    if ! has $stable $(get_remote_branches) || [ -z "$(get_last_tag)" ]; then
        process_fetch
    fi
    if ! has $stable $(get_remote_branches); then
        die "Remote $TWGIT_STABLE branch not found: '$TWGIT_ORIGIN/$TWGIT_STABLE'!"
    fi
    if [ -z "$(get_last_tag)" ]; then
        die "No tag found with format: '${TWGIT_PREFIX_TAG}X.Y.Z'!"
    fi
}

##
# S'assure que les 2 branches spécifiées sont au même niveau de mise à jour.
# Gère l'option '-I' permettant de répondre automatiquement (mode non interactif) oui à la demande de pull.
#
# @param string $1 nom complet d'une branche locale
# @param string $2 nom complet d'une branche distante
#
function assert_branches_equal () {
    CUI_displayMsg processing "Compare branches '$1' with '$2'..."
    if ! has $1 $(get_local_branches); then
        die "Local branch '<b>$1</b>' does not exist and is required!"
    elif ! has $2 $(get_remote_branches); then
        die "Remote branch '<b>$2</b>' does not exist and is required!"
    fi

    compare_branches "$1" "$2"
    local status=$?
    if [ $status -gt 0 ]; then
        CUI_displayMsg warning "Branches '<b>$1</b>' and '<b>$2</b>' have diverged."
        if [ $status -eq 1 ]; then
            CUI_displayMsg warning "And local branch '<b>$1</b>' may be fast-forwarded!"
            if ! isset_option 'I'; then
                echo -n $(CUI_displayMsg question "Pull '$1'? [y/N] "); read answer
                [ "$answer" != "Y" ] && [ "$answer" != "y" ] && die "Pull aborted! You must make a 'git pull $TWGIT_ORIGIN $1' to continue."
            fi
            exec_git_command "git checkout $1" "Checkout '$1' failed!"
            exec_git_command "git merge $2" "Update '$1' failed!"
        elif [ $status -eq 2 ]; then
            # Warn here (not die), since there is no harm in being ahead:
            CUI_displayMsg warning "And local branch '<b>$1</b>' is ahead of '<b>$2</b>'."
        else
            die "Branches need merging first!"
        fi
    fi
}

##
# S'assure que la branche spécifiée n'existe pas déjà en local, sinon effectue un checkout dessus,
# puis indique la fraîcheur de la branche locale vis-à-vis de la distante,
# puis affiche un warning si des tags ne sont pas présents dans la branche spécifiée, avant exit.
# Une erreur est affichée si la branche distante n'existe pas quand la locale existe.
#
# @param string $1 nom complet d'une branche potentiellement locale
#
function assert_new_local_branch () {
    local branch="$1"
    CUI_displayMsg processing 'Check local branches...'
    if has $branch $(get_local_branches); then
        CUI_displayMsg processing "Local branch '$branch' already exists!"
        if ! has "$TWGIT_ORIGIN/$branch" $(get_remote_branches); then
            CUI_displayMsg error "Remote feature '$TWGIT_ORIGIN/$branch' not found while local one exists!"
            CUI_displayMsg help 'Perhaps:'
            CUI_displayMsg help_detail "- check the name of your branch"
            CUI_displayMsg help_detail "- delete this out of process local branch: git branch -D $branch"
            CUI_displayMsg help_detail "- or force renewal if feature: twgit feature start -d xxxx"
        else
            exec_git_command "git checkout $branch" "Could not checkout '$branch'!"
            inform_about_branch_status "$branch"
            alert_old_branch "$TWGIT_ORIGIN/$branch" 'with-help'
        fi
        echo
        exit 0
    fi
}

##
# S'assure que le dépôt git courant est dans le status 'working directory clean'.
# @testedby TwgitCommonAssertsTest
#
function assert_clean_working_tree () {
    CUI_displayMsg processing 'Check clean working tree...'
    if [ `git status --porcelain --ignore-submodules=all | wc -l` -ne 0 ]; then
        CUI_displayMsg error 'Untracked files or changes to be committed in your working tree!'
        exec_git_command 'git status' 'Git status failed!'
        exit 1
    fi
}

##
# S'assure que la référence fournie est un nom syntaxiquement correct de branche potentielle.
#
# @param string $1 référence de branche
# @testedby TwgitCommonAssertsTest
#
function assert_valid_ref_name () {
    CUI_displayMsg processing 'Check valid ref name...'
    git check-ref-format --branch "$1" 1>/dev/null 2>&1
    if [ $? -ne 0 ]; then
        die "'<b>$1</b>' is not a valid reference name! See <b>git check-ref-format</b> for more details."
    fi

    echo " $1 " | grep -v " $TWGIT_PREFIX_FEATURE" \
        | grep -v " $TWGIT_PREFIX_RELEASE" \
        | grep -v " $TWGIT_PREFIX_HOTFIX" \
        | grep -v " $TWGIT_PREFIX_DEMO" 1>/dev/null
    if [ $? -ne 0 ]; then
        msg="Unauthorized reference: '$1'! Pick another name without using any prefix"
        msg="$msg ('$TWGIT_PREFIX_FEATURE', '$TWGIT_PREFIX_RELEASE', '$TWGIT_PREFIX_HOTFIX', '$TWGIT_PREFIX_DEMO')."
        die "$msg"
    fi
}

##
# S'assure que la référence fournie est un nom syntaxiquement correct de tag,
# c'est-à-dire au format \d+.\d+.\d+
#
# @param string $1 référence de tag sans préfixe
# @testedby TwgitCommonAssertsTest
#
function assert_valid_tag_name () {
    local tag="$1"
    assert_valid_ref_name "$tag"
    CUI_displayMsg processing 'Check valid tag name...'
    echo "$tag" | grep -qE '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' \
        && [ "$tag" != '0.0.0' ] \
        || die "Unauthorized tag name: '<b>$tag</b>'! Must use <major.minor.revision> format, e.g. '1.2.3'."
}

##
# S'assure que la référence fournie est un nom syntaxiquement correct de tag potentiel et qu'il est disponible.
#
# @param string $1 référence de tag sans préfixe
# @testedby TwgitCommonAssertsTest
#
function assert_new_and_valid_tag_name () {
    local tag="$1"
    local tag_fullname="$TWGIT_PREFIX_TAG$tag"
    assert_valid_tag_name "$tag"
    CUI_displayMsg processing "Check whether tag '$tag' already exists..."
    if has "$tag_fullname" $(get_all_tags); then
        die "Tag '<b>$tag_fullname</b>' already exists! Try: twgit tag list"
    fi
}

##
# S'assure que l'on ne tente pas de supprimer une branche sur laquelle on se trouve (checkout),
# auquel cas on checkout sur $TWGIT_STABLE.
#
# @param string $1 nom complet de la branche locale en instance de suppression
# @testedby TwgitCommonAssertsTest
#
function assert_working_tree_is_not_on_delete_branch () {
    local branch="$1"
    CUI_displayMsg processing "Check current branch..."
    if [ "$(get_current_branch)" = "$branch" ]; then
        CUI_displayMsg processing "Cannot delete the branch '$branch' which you are currently on! So:"
        exec_git_command "git checkout $TWGIT_STABLE" "Could not checkout '$TWGIT_STABLE'!"
    fi
}

##
# S'assure qu'au moins un tag existe.
# @testedby TwgitCommonAssertsTest
#
function assert_tag_exists () {
    CUI_displayMsg processing 'Get last tag...'
    local last_tag="$(get_last_tag)"
    [ -z "$last_tag" ] && die 'No tag exists!' || echo "Last tag: $last_tag"
}

##
# S'assure que l'outil Git est au moins dans la version $1.
#
# @param string $1 version minimale requise, au format '1.2.3' ou '1.2.3.4'
#
function assert_recent_git_version () {
    local needed=$(echo "$1" | awk -F. '{ printf("%d%02d%02d%02d\n", $1,$2,$3,$4); }')
    local current=$(git --version | sed 's/[^0-9.]//g' | awk -F. '{ printf("%d%02d%02d%02d\n", $1,$2,$3,$4); }')
    if [ $current -lt $needed ]; then
        CUI_displayMsg error "Please update git! Current: $(git --version | sed 's/[^0-9.]//g'). Need $1 or newer."
        CUI_displayMsg help 'Try:'
        CUI_displayMsg help_detail 'sudo apt-add-repository ppa:git-core/ppa'
        CUI_displayMsg help_detail 'sudo apt-get update'
        CUI_displayMsg help_detail 'sudo apt-get install git'
        echo
        exit
    fi
}

##
# Check that no commit occurs in stable branch not already present in origin/stable.
#
# @testedby TwgitHotfixTest
# @testedby TwgitReleaseTest
#
function assert_clean_stable_branch_and_checkout () {
    exec_git_command "git checkout $TWGIT_STABLE" "Could not checkout '$TWGIT_STABLE'!"
    CUI_displayMsg processing "Check health of '$TWGIT_STABLE' branch..."
    local extra_commits="$(git log ${TWGIT_ORIGIN}/${TWGIT_STABLE}..${TWGIT_STABLE} --oneline | wc -l)"
    if [ "$extra_commits" -gt 0 ]; then
        die "Local '<b>$TWGIT_STABLE</b>' branch is ahead of '<b>$TWGIT_ORIGIN/$TWGIT_STABLE</b>'!" \
            "Commits on '<b>$TWGIT_STABLE</b>' are out of process." \
            "Try: git checkout $TWGIT_STABLE && git reset $TWGIT_ORIGIN/$TWGIT_STABLE"
    fi
    exec_git_command "git merge $TWGIT_ORIGIN/$TWGIT_STABLE" \
        "Could not merge '$TWGIT_ORIGIN/$TWGIT_STABLE' into '$TWGIT_STABLE'!"
}

##
# S'assure que la branche existe dans le dépôt distant.
#
# @param string $1 nom complet de la branche
# @testedby TwgitCommonAssertsTest
#
function assert_remote_branch_exists () {
    local branch_fullname="$1"
    CUI_displayMsg processing 'Check remote branches...'
    if ! has "$TWGIT_ORIGIN/$branch_fullname" $(get_remote_branches); then
        CUI_displayMsg error "Remote branch '$TWGIT_ORIGIN/$branch_fullname' not found!"
        CUI_displayMsg help "Perhaps:"
        CUI_displayMsg help_detail "- check the name of the branch"
        CUI_displayMsg help_detail "- check if the branch has been deleted"
        echo
        exit 1
    fi
}


#--------------------------------------------------------------------
# Traitements
#--------------------------------------------------------------------

##
# Effectue un fetch avec prise en compte des éventuelles suppressions de branches.
#
# @testedby TwgitSetupTest
#
function process_fetch () {
    local option="$1"
    if [ -z "$option" ] || ! isset_option "$option"; then
        exec_git_command "git fetch --prune $TWGIT_ORIGIN" "Could not fetch '$TWGIT_ORIGIN'!"
    fi
    if [ ! -z "$option" ] && ! isset_option "$option"; then
        echo
    fi
}

##
# Réalise un commit "blanc" permettant de dégager la référence de la branche courante de celle dont elle est issue.
# Dit autrement, la première ne sera plus un ancêtre de la seconde.
#
# @param string $1 titre à inclure dans le message de commit
# @param string $2 nom complet de la branche à décaler
# @param string $3 éventuelle description additionnelle
# @see $TWGIT_FIRST_COMMIT_MSG
#
function process_first_commit () {
    local commit_msg=$(printf "$TWGIT_FIRST_COMMIT_MSG" "$1" "$2" "$3")
    CUI_displayMsg processing "${TWGIT_GIT_COMMAND_PROMPT}git commit --allow-empty -m \"$commit_msg\""
    git commit --allow-empty -m "$commit_msg" || die 'Could not make initial commit!'
}

##
# Réalise un push de la branche locale spécifiée sur $TWGIT_ORIGIN.
#
# @param string $1 nom complet de la branche locale à pousser
#
function process_push_branch () {
    local branch="$1"
    exec_git_command "git push --set-upstream $TWGIT_ORIGIN $branch" "Could not push '$branch' local branch on '$TWGIT_ORIGIN'!"
}

##
# Exécute la commande git spécifiée, affiche un message utilisateur et est à l'affût d'une éventuelle erreur d'exécution.
# NB : ne pas utiliser si des quotes sont nécessaires pour délimiter des paramètres de la commande...
# http://mywiki.wooledge.org/BashFAQ/050
#
# @param string $1 commande à exécuter
# @param string $2 message d'erreur pour le cas où...
# @testedby TwgitCommonProcessingTest
#
function exec_git_command () {
    local cmd="$1"
    local error_msg="$2"
    CUI_displayMsg processing "$TWGIT_GIT_COMMAND_PROMPT$cmd"
    $cmd || die "$error_msg"
}

##
# Supprime la branche locale spécifiée.
#
# @param string $1 nom complet de la branche locale
# @testedby TwgitCommonProcessingTest
#
function remove_local_branch () {
    local branch="$1"
    if has $branch $(get_local_branches); then
        exec_git_command "git branch -D $branch" "Remove local branch '$branch' failed!"
    else
        CUI_displayMsg processing "Local branch '$branch' not found."
    fi
}

##
# Supprime la branche distante spécifiée.
#
# @param string $1 nom complet de la branche distante sans le '$TWGIT_ORIGIN/'
# @testedby TwgitCommonProcessingTest
#
function remove_remote_branch () {
    local branch="$1"
    if has "$TWGIT_ORIGIN/$branch" $(get_remote_branches); then
        exec_git_command "git push $TWGIT_ORIGIN :$branch" "Delete remote branch '$TWGIT_ORIGIN/$branch' failed!"
    else
        die "Remote branch '<b>$TWGIT_ORIGIN/$branch</b>' not found!"
    fi
}

##
# Supprime la branche spécifiée, à la fois locale et distante.
# Suppose que les noms local et distant sont identiques.
#
# @param string $1 nom court de la branche locale
# @param string $2 préfixe de branche, par exemple $TWGIT_PREFIX_FEATURE
# @testedby TwgitCommonProcessingTest
#
function remove_branch () {
    local branch="$1"
    local branch_prefix="$2"
    local branch_fullname="$branch_prefix$branch"

    assert_valid_ref_name $branch
    assert_clean_working_tree
    assert_working_tree_is_not_on_delete_branch $branch_fullname

    process_fetch
    remove_local_branch $branch_fullname
    remove_remote_branch $branch_fullname
}

##
# Supprime la branche locale et distante de la feature spécifiée.
#
# @param string $1 nom court de la feature
# @testedby TwgitCommonProcessingTest
#
function remove_feature () {
    remove_branch $1 $TWGIT_PREFIX_FEATURE
}

##
# Supprime la branche locale et distante de la demo spécifiée.
#
# @param string $1 nom court de la demo
# @testedby TwgitCommonProcessingTest
#
function remove_demo () {
    remove_branch $1 $TWGIT_PREFIX_DEMO
}

##
# Crée un tag sur la branche courante puis le pousse.
#
# @param string $1 nom complet du tag
# @param string $2 message du commit du tag, qui sera préfixé par $TWGIT_PREFIX_COMMIT_MSG
#
function create_and_push_tag () {
    local tag_fullname="$1"
    local commit_msg="$2"

    # Create tag:
    CUI_displayMsg processing "${TWGIT_GIT_COMMAND_PROMPT}git tag -a $tag_fullname -m \"${TWGIT_PREFIX_COMMIT_MSG}$commit_msg\""
    git tag -a $tag_fullname -m "${TWGIT_PREFIX_COMMIT_MSG}$commit_msg" || die "Could not create tag '<b>$tag_fullname</b>'!"

    # Push tags:
    exec_git_command "git push --tags $TWGIT_ORIGIN $TWGIT_STABLE" "Could not push '$TWGIT_STABLE' on '$TWGIT_ORIGIN'!"
}

##
# Crée une branche du type feature ou démo à partir du dernier tag, ou d'une branche source.
# Gère l'option '-d' supprimant préalablement la feature locale, afin de forcer le récréation de la branche.
#
# @param string $1 nom court de la nouvelle branche.
# @param string $2 préfixe de branche, par exemple $TWGIT_PREFIX_FEATURE ou $TWGIT_PREFIX_DEMO.
# @param string $3 type de la branche source à partir de laquelle créer la branche (optionnel).
# @param string $4 nom court de la branche source (requis pour une branche source de type 'feature' ou 'demo').
#
function start_simple_branch () {
    local branch="$1"
    local branch_prefix="$2"
    local source_branch_type="$3"
    local source_branch_name="$4"
    local branch_fullname="$branch_prefix$branch"
    local source_branch_fullname=''

    local -A wording=(
        [$TWGIT_PREFIX_FEATURE]='feature'
        [$TWGIT_PREFIX_DEMO]='demo'
    )
    local branch_type="${wording[$branch_prefix]}"

    assert_valid_ref_name $branch
    assert_clean_working_tree
    process_fetch

    if [ ! -z "$source_branch_type" ]; then
        if [ "$source_branch_type" = 'release' ]; then
            source_branch_fullname=$(get_current_release_in_progress)
            [ -z "$source_branch_fullname" ] && die 'No release in progress!'
        else
            source_branch_fullname="$(prefix_of $source_branch_type)$source_branch_name"
            assert_remote_branch_exists "$source_branch_fullname"
        fi
    fi

    if isset_option 'd'; then
        if has $branch_fullname $(get_local_branches); then
            assert_working_tree_is_not_on_delete_branch $branch_fullname
            remove_local_branch $branch_fullname
        fi
    else
        assert_new_local_branch $branch_fullname
    fi

    CUI_displayMsg processing "Check remote ${branch_type}s..."
    if has "$TWGIT_ORIGIN/$branch_fullname" $(get_remote_branches); then
        CUI_displayMsg processing "Remote $branch_type '$branch_fullname' detected."
        exec_git_command "git checkout --track -b $branch_fullname $TWGIT_ORIGIN/$branch_fullname" "Could not check out $branch_type '$TWGIT_ORIGIN/$branch_fullname'!"
    else
        if [ -z "$source_branch_fullname" ]; then
            assert_tag_exists
            local last_tag=$(get_last_tag)
            exec_git_command "git checkout -b $branch_fullname tags/$last_tag" "Could not check out tag '$last_tag'!"
        else
            exec_git_command "git checkout -b $branch_fullname $TWGIT_ORIGIN/$source_branch_fullname" "Could not check out $source_branch_type '$TWGIT_ORIGIN/$source_branch_fullname'!"
        fi

        local subject="$(getFeatureSubject "$branch")"
        [ ! -z "$subject" ] && subject=": $subject"
        process_first_commit "$branch_type" "$branch_fullname" "$subject"

        process_push_branch $branch_fullname
        inform_about_branch_status $branch_fullname
    fi
    alert_old_branch $TWGIT_ORIGIN/$branch_fullname with-help
}

##
# Exécutes les commandes de merge de la feature spécifiée dans la branche de destination, release, hotfix ou demo.
# Si le merge automatique ne peut se faire à cause de conflits, alors affiche les instructions
# restantes pour accomplir le merge, puis exécute un "exit 1".
#
# @param string $1 nom court de la feature à merger dans la branche de destination
# @param string $2 nom long de la release, du hotfix ou de la demo devant recevoir la feature, sans le "$TWGIT_ORIGIN/"
#
function merge_feature_into_branch () {
    local feature="$1"
    local dest_branch_fullname="$2"
    local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"

    # Tests :
    CUI_displayMsg processing 'Check remote feature...'
    if ! has "$TWGIT_ORIGIN/$feature_fullname" $(get_remote_branches); then
        die "Remote feature '<b>$TWGIT_ORIGIN/$feature_fullname</b>' not found!"
    fi

    # Merge :
    local start_branch_cmd
    if [ "${dest_branch_fullname:0:${#TWGIT_PREFIX_RELEASE}}" = "$TWGIT_PREFIX_RELEASE" ]; then
        start_branch_cmd="$TWGIT_EXEC release start"
    elif [ "${dest_branch_fullname:0:${#TWGIT_PREFIX_HOTFIX}}" = "$TWGIT_PREFIX_HOTFIX" ]; then
        start_branch_cmd="$TWGIT_EXEC hotfix start"
    else
        start_branch_cmd="$TWGIT_EXEC demo start ${dest_branch_fullname:${#TWGIT_PREFIX_DEMO}}"
    fi

    local cmds="$TWGIT_EXEC feature start $feature
git pull $TWGIT_ORIGIN $feature_fullname
$start_branch_cmd
git pull $TWGIT_ORIGIN $dest_branch_fullname
git merge --no-ff $feature_fullname
git push $TWGIT_ORIGIN $dest_branch_fullname"
    IFS="$(echo -e "\n\r")"
    local error=0
    for cmd in $cmds; do
        if [ "$error" -ne 0 ]; then
            CUI_displayMsg help_detail "$cmd"
        else
            [ "${cmd:0:${#TWGIT_EXEC}+1}" = "$TWGIT_EXEC " ] && msg="shell# twgit ${cmd:${#TWGIT_EXEC}+1}" || msg="${TWGIT_GIT_COMMAND_PROMPT}$cmd"
            CUI_displayMsg processing "$msg"
            if ! eval $cmd; then
                error=1
                CUI_displayMsg error "Merge '$feature_fullname' into '$dest_branch_fullname' aborted!"
                CUI_displayMsg help 'Commands not executed:'
                CUI_displayMsg help_detail "$cmd"
                if [ "${cmd:0:10}" = "git merge " ]; then
                    CUI_displayMsg help_detail "  - resolve conflicts"
                    CUI_displayMsg help_detail "  - git add..."
                    CUI_displayMsg help_detail "  - git commit..."
                fi
            fi
        fi
    done
    echo
    [ "$error" -eq 0 ] || exit 1
}



#--------------------------------------------------------------------
# Autres fonctions...
#--------------------------------------------------------------------

##
# Display an error message, then exit with exit code 1.
#
# @param string $@ error message to display on error channel
#
function die () {
    CUI_displayMsg error "$*" >&2
    echo
    exit 1
}

##
# Échappe les caractères '.+$*[]' d'une chaîne.
#
# @param string $1 chaîne à échapper
#
function escape () {
    echo "$1" | sed 's/\([\.\+\$\*\[]\|\]\)/\\\1/g'
}

##
# Retourne 0 si la chaîne $1 est présente dans la concaténation du reste des paramètres, 1 sinon.
#
# @param string $1 chaîne à rechercher
# @param string $2..$n chaînes dans lesquelles rechercher
# @return int 0 si la chaîne $1 est présente dans la concaténation du reste des paramètres, 1 sinon.
#
function has () {
    local item=$1; shift
    echo " $@ " | grep -q " $(escape $item) "
}

##
# Tests whether branches and their "origin" counterparts have diverged and need
# merging first. It returns error codes to provide more detail, like so:
#
# @return int
#    0    Branch heads point to the same commit
#    1    First given branch needs fast-forwarding
#    2    Second given branch needs fast-forwarding
#    3    Branch needs a real merge
#    4    There is no merge base, i.e. the branches have no common ancestors
#
# @author http://github.com/nvie/gitflow
#
function compare_branches () {
    local commit1=$(git rev-parse "$1")
    local commit2=$(git rev-parse "$2")
    if [ "$commit1" != "$commit2" ]; then
        local base=$(git merge-base "$commit1" "$commit2")
        if [ $? -ne 0 ]; then
            return 4
        elif [ "$commit1" = "$base" ]; then
            return 1
        elif [ "$commit2" = "$base" ]; then
            return 2
        else
            return 3
        fi
    else
        return 0
    fi
}

##
# Affiche une ligne CSV pour chacune des branches fournies.
# Exemple :
#    7278;feature-7278;merged into release;"Mail d\'alerte en cas d\'insertion KO dans Sugar"
#
# @param string $1 liste des branches à présenter, à raison d'une par ligne, au format 'origin/xxx'
# @param string $2 information de sous-type de branche
#
function display_csv_branches () {
    local branches="$1"
    local subtype="$2"
    local repo_prefix="$TWGIT_ORIGIN/"
    local prefix="$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE"

    local subject
    local short_name
    for branch in $branches; do
        short_name="${branch:${#prefix}}"
        subject="$(getFeatureSubject "$short_name")"
        echo "${branch:${#repo_prefix}};$short_name;$subtype;$(convertList2CSV "$subject")"
    done
}

##
# Affiche un court paragraphe descriptif pour chacune des branches fournies.
# Exemple :
#    [title]: origin/release-three
#    commit 9723329ce24daf342fdd04e8de4d58966dbf2609
#    Author: Geoffroy Aubry <geoffroy.aubry@twenga.com>
#    Date:   Wed May 25 18:58:05 2011 +0200
#
# @param string $1 type type de branches affichées, parmi {'demo', 'feature', 'release', 'hotfix'}
# @param string $2 liste des branches à présenter, à raison d'une par ligne, au format 'origin/xxx'
#
function display_branches () {
    local type="$1"
    local branches="$2"
    local -A titles=(
        [feature]='Feature: '
        [release]='Release: '
        [hotfix]='Hotfix: '
        [demo]='Demo: '
    )
    local current_branch=$(get_current_branch)

    if [ -z "$branches" ]; then
        CUI_displayMsg info 'No such branch exists.';
    else
        local prefix="$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE"
        local add_empty_line=0
        local stable_origin
        for branch in $branches; do
            if ! isset_option 'c'; then
                [ "$add_empty_line" = "0" ] && add_empty_line=1 || echo
            fi

            echo -n $(CUI_displayMsg info "${titles[$type]}$branch")
            if [[ $type = 'feature' && $current_branch = "${branch#$TWGIT_ORIGIN/}" ]]; then
                echo -n $(CUI_displayMsg current_branch '*')
            fi
            stable_origin="$(git describe --abbrev=0 "$branch" 2>/dev/null)"
            echo -n $(CUI_displayMsg help_detail " (from <b>$stable_origin</b>) ")

            [ "$type" = "feature" ] && displayFeatureSubject "${branch:${#prefix}}" || echo

            alert_old_branch "$branch"

            # Afficher les informations de commit :
            ! isset_option 'c' && git show $branch --pretty=medium | grep -v '^Merge: ' | head -n 3
        done
    fi
}

##
# Affiche une release ou une branche de démo avec les features incluses
# et catégorisées en 'merged' ou 'merged, then in progress'.
#
# @param string $1 type type de super branche, parmi {'release', 'demo'}
# @param string $2 nom complet de la branche distante, sans le "$TWGIT_ORIGIN/"
#
function display_super_branch () {
    local type="$1"	# 'release', 'demo'
    local super_branch="$2"	# 'demo-X', 'release-Y'
    display_branches "$type" "$TWGIT_ORIGIN/$super_branch" # | head -n -1
    CUI_displayMsg info 'Features:'

    get_merged_features $super_branch
    local merged_features="$GET_MERGED_FEATURES_RETURN_VALUE"

    local prefix="$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE"
    for f in $merged_features; do
        echo -n "    - $f "
        echo -n $(CUI_displayMsg ok '[merged]')' '
        displayFeatureSubject "${f:${#prefix}}"
    done

    get_features merged_in_progress $super_branch
    local merged_in_progress_features="$GET_FEATURES_RETURN_VALUE"

    for f in $merged_in_progress_features; do
        echo -n "    - $f ";
        echo -n $(CUI_displayMsg warning 'merged, then in progress.')' '
        displayFeatureSubject "${f:${#prefix}}"
    done
    if [ -z "$merged_features" ] && [ -z "$merged_in_progress_features" ]; then
        CUI_displayMsg info '    - No such branch exists.'
    fi
}

##
# Affiche un warning si des tags ne sont pas présents dans la branche spécifiée.
#
# @param string $1 nom complet de la branche, locale ou distante
# @param string $2 si présent et vaut 'with-help', alors une suggestion de merge sera proposée
#
function alert_old_branch () {
    local branch_fullname="$1"
    local branch="${branch_fullname#$TWGIT_ORIGIN/}"

    get_tags_not_merged_into_branch "$branch_fullname"
    local tags_not_merged="$GET_TAGS_NOT_MERGED_INTO_BRANCH_RETURN_VALUE"
    local nb_tags_no_merged="$(echo "$tags_not_merged" | wc -w)"

    if [ ! -z "$tags_not_merged" ]; then
        local msg='Tag'
        if echo "$tags_not_merged" | grep -q ' '; then
            msg="${msg}s"
        fi
        msg="${msg} not merged into this branch:"
        [ "$nb_tags_no_merged" -eq "$TWGIT_MAX_RETRIEVE_TAGS_NOT_MERGED" ] && msg="${msg} at least"
        msg="${msg} $(displayInterval "$tags_not_merged")."
        [ "$2" = 'with-help' ] && msg="${msg} If need be: git merge --no-ff $(get_last_tag) && git push $TWGIT_ORIGIN $branch"
        CUI_displayMsg warning "$msg"
    fi
}

##
# Affiche un warning si des branches sont hors process.
# N'affiche rien si l'option -x est activée (pour les rendus CSV).
#
# @testedby TwgitSetupTest
#
function alert_dissident_branches () {
    if ! isset_option 'x'; then
        local dissident_branches="$(get_dissident_remote_branches)"
        if [ ! -z "$dissident_branches" ]; then
            CUI_displayMsg warning "Following branches are out of process: $(displayQuotedEnum $dissident_branches)!"
        fi
    fi

    local local_ambiguous_branches="$((get_local_branches; git tag) | sort | uniq -d)"
    if [ ! -z "$local_ambiguous_branches" ]; then
        CUI_displayMsg warning "Following local branches are ambiguous: $(displayQuotedEnum $local_ambiguous_branches)!"
    fi

    if [ ! -z "$dissident_branches" ] || [ ! -z "$local_ambiguous_branches" ]; then
        echo
    fi
}

##
# Affiche un interval "a to z" à partir du premier et du dernier élément de la liste fournie.
# N'affiche que le premier élément s'il est seul.
#
# @param string $@ liste de valeurs séparées par des espaces
# @testedby TwgitCommonToolsTest
#
function displayInterval () {
    local -a list=($@)
    local nb_items="${#list[@]}"

    if [ "$nb_items" -gt 0 ]; then
        local first_item="${list[0]}"
        local last_item="${list[$((nb_items-1))]}"

        echo -n "'<b>$first_item</b>'"
        [ "$nb_items" -gt 1 ] && echo " to '<b>$last_item</b>'" || echo
    fi
}

##
# Affiche la liste de valeurs sur une seule ligne, séparées par des virgules
# et chaque valeur entre balises <b>…</b> et simples quotes.
#
# @param string $@ liste de valeurs sur une ou plusieurs lignes, séparées par des espaces ou des sauts de ligne
# @testedby TwgitCommonToolsTest
#
function displayQuotedEnum () {
    local list="$@"
    local one_line_list="$(echo $list | tr '\n' ' ')"
    local trimmed_list="$(echo $one_line_list)"

    if [ -z "$trimmed_list" ]; then
        echo
    else
        local quoted_list="'<b>${trimmed_list// /</b>\', \'<b>}</b>'"
        echo $quoted_list
    fi
}

##
# Affiche le sujet d'une feature en le récupérant
# d'une plate-forme Redmine, Github ou autre via le connecteur défini
# par TWGIT_FEATURE_SUBJECT_CONNECTOR.
#
# Le premier appel sollicite le connecteur concerné,
# les suivants bénéficieront du fichier de cache $TWGIT_FEATURES_SUBJECT_PATH.
#
# @param string $1 nom court de la feature
# @param string $2 sujet sur échec, optionnel
# @see getFeatureSubject()
# @testedby TwgitCommonGettersTest
#
function displayFeatureSubject () {
    local subject="$(getFeatureSubject "$1")"
    [ -z "$subject" ] && subject="$2"
    [ ! -z "$subject" ] && CUI_displayMsg feature_subject "$subject" || echo
}

##
# @param string $1 nom long du tag à afficher
#
function displayTag () {
    local tag="$1"
    local msg pattern features feature_shortname feature_subject

    CUI_displayMsg info "Tag: $tag"
    msg="$(git show tags/$tag --pretty=medium)"
    echo "$msg" | head -n3 | tail -n+2
    pattern="${TWGIT_PREFIX_COMMIT_MSG}Contains $TWGIT_PREFIX_FEATURE"
    features="$(echo "$msg" | grep -F "$pattern" | sedRegexpExtended "s/^.*$TWGIT_PREFIX_FEATURE//")"
    if [ -z "$features" ]; then
        if ! git show $tag^2 1>/dev/null 2>&1; then
            CUI_displayMsg info "No feature included and it's the first tag."
        else
            local previous_tag="$(git describe --abbrev=0 $tag^2)"
            CUI_displayMsg info "Commit logs from $previous_tag tag:"
            git log --no-merges --pretty='oneline' --abbrev-commit $previous_tag..$tag | grep -v "$(escape "$TWGIT_PREFIX_COMMIT_MSG")"
        fi
    else
        CUI_displayMsg info 'Included features:'
        echo "$features" | while read line; do
            (echo "$line" | grep -q '^.*: ".*"$') || line="$line: \"\""
            feature_shortname="$(echo "$line" | sedRegexpExtended "s/^(.*): \".*$/\1/")"
            feature_subject="$(echo "$line" | sedRegexpExtended "s/^.*: \"(.*)\"$/\1/")"
            [ -z "$feature_subject" ] && feature_subject="$(getFeatureSubject "$feature_shortname")"
            echo -n "    - $TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE$feature_shortname "
            displayFeatureSubject "$feature_shortname" "$feature_subject"
        done
    fi
}

##
# Informe de l'état de la branche : à jour, en avance, en retard, a divergé.
# Propose des commandes à exécuter.
#
# @param string $1 nom complet d'une branche potentiellement locale
#
function inform_about_branch_status () {
    local branch="$1"
    compare_branches "$branch" "$TWGIT_ORIGIN/$branch"
    local status=$?
    if [ $status -eq 0 ]; then
        CUI_displayMsg help "Local branch '<b>$branch</b>' up-to-date with remote '<b>$TWGIT_ORIGIN/$branch</b>'."
    elif [ $status -eq 1 ]; then
        CUI_displayMsg help "If need be: git merge $TWGIT_ORIGIN/$branch"
    elif [ $status -eq 2 ]; then
        CUI_displayMsg help "If need be: git push $TWGIT_ORIGIN $branch"
    else
        CUI_displayMsg warning "Branches '<b>$branch</b>' and '<b>$TWGIT_ORIGIN/$branch</b>' have diverged!"
        CUI_displayMsg help "If need be: git merge $TWGIT_ORIGIN/$branch"
        CUI_displayMsg help "Then: git push $TWGIT_ORIGIN $branch"
    fi
}

##
# Convertit une liste de valeurs en une ligne CSV au format suivant et l'affiche : "v1";"va""lue2";"v\'3"
# Attention, les blancs inter et intra paramètre bash sont remplacés par un unique espace.
#
# @param string $1..$n liste de valeurs
# @testedby TwgitCommonToolsTest
#
function convertList2CSV () {
    local row
    for v in "$@"; do
        v=${v//'"'/'""'}
        v=${v//"'"/"\\'"}
        row="$row;\"$v\""
    done
    echo ${row:1}
}

##
# Analyse les prochains paramètres de la ligne de commande pour déduire la branche source demandée par
# l'utilisateur. S'attend à dépiler les paramètres 'from-<source_type> <source_name>'.
# Le résultat est stocké dans la variable $RETVAL, et contient le type de la branche source et son
# nom court (s'il s'agit d'une branche source de type 'feature' ou 'demo').
#
# Si le premier paramètre n'est pas de la forme 'from-<source_type>' ou si <source_type> ne fait pas
# parti des types demandés, une erreur est levée.
#
# Si aucun paramètre n'est dépilé, $RETVAL est vide.
#
# @param string $1..$n Liste des types possibles de la branche source
#
function parse_source_branch_info () {
    require_parameter '-'
    local keyword="$RETVAL"

    if [ ! -z "$keyword" ]; then

        for type in "$@"; do
            if [ "$keyword" = "from-$type" ]; then

                if [ "$type" = 'release' ]; then
                    RETVAL="$type"
                else
                    require_parameter "${type}name"
                    clean_prefixes "$RETVAL" "$type"
                    local source_branch="$RETVAL"
                    RETVAL="$type $source_branch"
                fi

                return
            fi
        done

        CUI_displayMsg error "Unknown action extension: '$RETVAL'!"
        usage
        exit 1
    else
        RETVAL=''
    fi
}

##
# Propose de supprimer une à une les branches qui ne sont plus trackées.
#
function clean_branches () {
    local tracked="$(git fetch --all -v --dry-run 2>&1 | grep '\->' | sedRegexpExtended 's/^.* +([^ ]+) +\-> +.*$/\1/')"
    local locales="$(get_local_branches)"
    for branch in $locales; do
        if ! has $branch $tracked; then
            echo -n $(CUI_displayMsg question "Local branch '<b>$branch</b>' is not tracked. Remove? [y/N] ")
            read answer
            if [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
                exec_git_command "git branch -D $branch" "Remove local branch '$branch' failed!"
            fi
        fi
    done
}

##
# Git init for Twgit:
#  - git init if necessary
#  - add remote origin if necessary
#  - create a stable branch if not exists or pull origin/stable branch if exists
#  - create a tag on HEAD of stable
# A remote repository must exists.
#
# @param string $1 tag name. Format: \d+.\d+.\d+
# @param string $2 optional url of remote repository. Used only if not already set.
# @testedby TwgitMainTest
#
function init () {
    process_options "$@"
    require_parameter 'tag'
    clean_prefixes "$RETVAL" 'tag'
    local tag="$RETVAL"
    local remote_url="$2"
    local tag_fullname="$TWGIT_PREFIX_TAG$tag"

    CUI_displayMsg processing "Check need for git init..."
    git rev-parse --git-dir 1>/dev/null 2>&1
    if [ $? -ne 0 ]; then
        exec_git_command 'git init' 'Initialization of git repository failed!'
    else
        assert_clean_working_tree
    fi

    assert_new_and_valid_tag_name $tag

    CUI_displayMsg processing "Check presence of remote '$TWGIT_ORIGIN' repository..."
    if [ "$(git remote | grep -E "^$TWGIT_ORIGIN$" | wc -l)" -ne 1 ]; then
        [ -z "$remote_url" ] && die "Remote '<b>$TWGIT_ORIGIN</b>' repository url required!"
        exec_git_command "git remote add $TWGIT_ORIGIN $remote_url" 'Add remote repository failed!'
    fi
    process_fetch

    CUI_displayMsg processing "Check presence of '$TWGIT_STABLE' branch..."
    if has $TWGIT_STABLE $(get_local_branches); then
        CUI_displayMsg processing "Local '$TWGIT_STABLE' detected."
        if ! has $TWGIT_ORIGIN/$TWGIT_STABLE $(get_remote_branches); then
            exec_git_command "git push --set-upstream $TWGIT_ORIGIN $TWGIT_STABLE" 'Git push failed!'
        fi
    elif has $TWGIT_ORIGIN/$TWGIT_STABLE $(get_remote_branches); then
        CUI_displayMsg processing "Remote '$TWGIT_ORIGIN/$TWGIT_STABLE' detected."
        exec_git_command "git checkout --track -b $TWGIT_STABLE $TWGIT_ORIGIN/$TWGIT_STABLE" \
                         "Could not check out '$TWGIT_ORIGIN/$TWGIT_STABLE'!"
    else
        if has $TWGIT_ORIGIN/master $(get_remote_branches); then
            exec_git_command "git checkout -b $TWGIT_STABLE $TWGIT_ORIGIN/master" "Could not check out '$TWGIT_ORIGIN/master'!"
        elif has master $(get_local_branches); then
            exec_git_command "git checkout -b $TWGIT_STABLE master" "Create local '$TWGIT_STABLE' branch failed!"
        else
            # @todo pas d'autre branche ?
            process_first_commit branch stable
            exec_git_command "git branch -m $TWGIT_STABLE" "Rename of master branch failed!"
        fi
        process_push_branch $TWGIT_STABLE
    fi

    # Add minimal .gitignore ignoring '/.twgit_features_subject'
    if [ ! -f '.gitignore' ]; then
        echo -e "/.twgit_features_subject\n/.twgit" > .gitignore
        exec_git_command "git add .gitignore" "Add minimal .gitignore failed!"
        CUI_displayMsg processing "${TWGIT_GIT_COMMAND_PROMPT}git commit -m 'Add minimal .gitignore'"
        git commit -m 'Add minimal .gitignore' || die 'Add minimal .gitignore failed!'
        exec_git_command "git push $TWGIT_ORIGIN $TWGIT_STABLE" "Add minimal .gitignore failed!"
    fi

    update_version_information "$tag"

    create_and_push_tag "$tag_fullname" "First tag."
}

##
# Affiche la liste des emails des N auteurs les plus significatifs (en nombre de commits)
# de la branche distante spécifiée, à raison d'un par ligne.
# Filtre les auteurs sans email ainsi que ceux en dehors du domaine '@$TWGIT_EMAIL_DOMAIN_NAME' si défini.
#
# @param string $1 nom complet de branche distante, sans le "$TWGIT_ORIGIN/"
# @param int $2 nombre maximum d'auteurs à afficher, optionnel (vaut $TWGIT_DEFAULT_NB_COMMITTERS par défaut)
# @see get_contributors()
# @testedby TwgitMainTest
#
function display_rank_contributors () {
    local branch_fullname="$1"
    local max="$2"
    [ -z "$max" ] && max=$TWGIT_DEFAULT_NB_COMMITTERS

    local header filter
    [ "$max" -eq 1 ] && header="First committer" || header="First $max committers"
    [ -z "$TWGIT_EMAIL_DOMAIN_NAME" ] && filter='' || filter=" (filtered by email domain: '@$TWGIT_EMAIL_DOMAIN_NAME')"
    CUI_displayMsg info "$header into '$TWGIT_ORIGIN/$branch_fullname' remote branch$filter:"
    local contributors="$(get_contributors "$branch_fullname" $max)"
    [ -z "$contributors" ] && echo 'nobody' || echo "$contributors"
    echo
}

##
# Display section of CHANGELOG.md from $from_tag (exclusive) to $to_tag (inclusive).
#
# @param string $1 Full name of $from_tag
# @param string $2 Full name of $to_tag
#
function displayChangelogSection () {
    local from_tag="$1"
    local to_tag="$2"

    local content="$(git show $to_tag:CHANGELOG.md)";
    content="## Version $(echo "${content#*## Version }")";
    content="$(echo "${content%## Version ${from_tag:1}*}")";
    content="$(echo -e "$content\n" \
        | sedRegexpExtended ':a;N;$!ba;s/\n\n(  -|```)/\n\1/g' \
        | sedRegexpExtended 's/  - \[#([0-9]+)\]\([^)]+\)/  - #\1/' \
    )";

    local line
    while read line; do
        if [[ "$line" =~ ^## ]]; then
            CUI_displayMsg help "${line:3}"
        elif [[ "$line" =~ ^[^-*\`].*:$ ]]; then
            CUI_displayMsg info "$line"
        else
            echo "  $line"
        fi;
    done <<< "$content"
}

##
# Retourne le prefix correspondant au type demandé.
#
# @param string $1 Type de la branche {'demo', 'feature', 'hotfix', 'release', 'tag'}
#
function prefix_of () {
    local type="$1"
    local -A prefixes=(
        [demo]="$TWGIT_PREFIX_DEMO"
        [feature]="$TWGIT_PREFIX_FEATURE"
        [hotfix]="$TWGIT_PREFIX_HOTFIX"
        [release]="$TWGIT_PREFIX_RELEASE"
        [tag]="$TWGIT_PREFIX_TAG"
    )
    echo ${prefixes[$type]}
}

##
# This add-on cleans the <<tag>> name sent to twgit.
# In case of call with use of prefix v (for init & tag), feature- (for feature),
# hotfix- (for hotfix) or demo- (for demos), then this function will automatically
# remove the 'unneeded' prefix and allows twgit to continue its execution.
# Result in $RETVAL.
#
# @param string $1 Full name of branch
# @param string $2 Branch type in {'demo', 'feature', 'hotfix', 'release', 'tag'}
# @testedby TwgitCommonToolsTest
#
function clean_prefixes () {
    local branch_name="$1"
    local type="$2"
    local prefix="$(prefix_of $type)"

    RETVAL="$branch_name"
    if [ ! -z "$prefix" ]; then
        if [[ $branch_name == $prefix* ]]; then
            RETVAL=$(echo $branch_name | sed -e 's/^'"$prefix"'//')
            CUI_displayMsg warning "Assume $type was '<b>$RETVAL</b>' instead of '<b>$branch_name</b>'…"
        fi
    fi
}

##
# This function permits to update all tags $Id$ with current version X.Y.Z inside files designed
# in a global variable TWGIT_VERSION_INFO_PATH (defined in some config file as
# .twgit on conf/twgit.sh).
# For example being in v1.2.3 and calling twgit release start
# will result in replacing all tags with $Id:1.3.0$.
#
# @param string $version Is the current version 'started' (with Hotfix and/or
# Release and/or Init)
# @testedby TwgitFeatureTest
# @testedby TwgitHotfixTest
# @testedby TwgitMainTest
#
function update_version_information () {
    local version="$1"

    if [[ ! -z $TWGIT_VERSION_INFO_PATH ]]; then
        CUI_displayMsg processing "Updating \$Id\$ tags in TWGIT_VERSION_INFO_PATH's files..."
        for filepath in $(echo $TWGIT_VERSION_INFO_PATH | tr ',' ' '); do
            if [[ -f $filepath ]]; then
                CUI_displayMsg processing "Updating $Id$ tags in $filepath..."
                sed -i -e 's/\$Id[:v0-9\.]*\$/$Id:'$version'$/g' "$filepath"
                exec_git_command "git add $filepath" "Could not add version info into $filepath!"
            else
                CUI_displayMsg warning "TWGIT_VERSION_INFO_PATH contains a non-existing file: $filepath!"
            fi
        done
    else
        CUI_displayMsg processing 'TWGIT_VERSION_INFO_PATH is empty: no $Id$ to update.'
    fi;
}

# This add-on checks if current user is the initial author of a branch creation.
#
# @param string $1 Name of branch
# @param string $2 Branch type in {'hotfix', 'release'}
# @testedby TwgitHotfixTest
# @testedby TwgitReleaseTest
#
function is_initial_author () {
    local branch_name="$1"
    local type="$2"
    local -A prefixes=(
        [hotfix]="$TWGIT_PREFIX_HOTFIX"
        [release]="$TWGIT_PREFIX_RELEASE"
    )

    CUI_displayMsg processing 'Check initial author...'

    # Retrieving Author Email & Name
    local branchAuthor=$(git log $TWGIT_ORIGIN/$TWGIT_STABLE..$TWGIT_ORIGIN/${prefixes[$type]}$branch_name --format="%an <%ae>" --first-parent --no-merges | tail -n1)

    # Retrieving Local Email & Name
    local localAuthorEmail=$(git config user.email)
    local localAuthorName=$(git config user.name)

    # Comparing Init Committer of Branch to Current Author
    if [ ! "$localAuthorName <$localAuthorEmail>" = "$branchAuthor" ]; then
        CUI_displayMsg warning "Remote $type '$TWGIT_ORIGIN/${prefixes[$type]}$branch_name' was started by $branchAuthor."
        if ! isset_option 'I'; then
            echo -n $(CUI_displayMsg question 'Do you want to continue? [y/N] '); read answer
            [ "$answer" != "Y" ] && [ "$answer" != "y" ] && die 'Warning, '$type' retrieving aborted!'
        fi
    fi
}

##
# Permet la mise à jour automatique de l'application dans le cas où le .git est toujours présent.
# Tous les $TWGIT_UPDATE_NB_DAYS jours un fetch sera exécuté afin de proposer à l'utilisateur une
# éventuelle MAJ. Qu'il décline ou non, le prochain passage aura lieu dans à nouveau $TWGIT_UPDATE_NB_DAYS jours.
#
# À des fins de test : "touch -mt 1105200101 ~/twgit/.lastupdate"
#
# @param string $1 Si vaut 'force', alors force la vérification de la présence d'une MAJ même
#    si $TWGIT_UPDATE_NB_DAYS jours ne se sont pas écoulés depuis le dernier test.
#    Mettre une autre valeur pour une mise à jour non forcée.
# @param string $2..$n éventuelle commande twgit avec ses paramètres à réexécuter après mise à jour non forcée.
#
function autoupdate () {
    local is_forced=0
    [ $1 = 'force' ] && is_forced=1
    shift

    cd "$TWGIT_ROOT_DIR"
    if git rev-parse --git-dir 1>/dev/null 2>&1; then
        [ ! -f "$TWGIT_UPDATE_PATH" ] && touch "$TWGIT_UPDATE_PATH"
        local elapsed_time=$(( ($(date -u +%s) - $(getLastUpdateTimestamp "$TWGIT_UPDATE_PATH")) ))
        local interval=$(( $TWGIT_UPDATE_NB_DAYS * 86400 ))
        local answer=''

        if [ "$elapsed_time" -gt "$interval" ] || [ "$is_forced" = 1 ]; then
            # Update Git :
            CUI_displayMsg processing "Fetch twgit repository for auto-update check..."
            git fetch

            # Retrieve both current and last tag:
            assert_tag_exists
            local current_tag="$(git describe --abbrev=0)"
            local current_ref_on_top=''
            if [ "$(git describe)" != "$current_tag" ]; then
                current_ref_on_top="$(git describe | sed 's/^.*-g//')"
            fi
            local last_tag="$(get_last_tag)"

            # If new update:
            if [ "$current_tag$current_ref_on_top" != "$last_tag" ]; then

                # Question:
                local question
                if [ "$current_tag" != "$last_tag" ]; then
                    echo -e 'New content of CHANGELOG.md:\n'
                    displayChangelogSection "$current_tag" "$last_tag"
                    echo
                    question="Do you want to update twgit from <b>$current_tag</b> to <b>$last_tag</b> (or manually: twgit update)? [y/N] "
                else
                    question="You are ahead of last tag <b>$last_tag</b>. Would you like to return to it? [y/N] "
                fi
                echo -n $(CUI_displayMsg question "\033[4m/!\ <b>twgit update</b>")
                echo -n $(CUI_displayMsg question ": $question")

                # Read answer:
                read answer
                if [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
                    CUI_displayMsg processing 'Update in progress...'
                    exec_git_command 'git reset --hard' 'Hard reset failed!'
                    exec_git_command "git checkout tags/$last_tag" "Could not check out tag '$last_tag'!"

                    # Bash autcompletion updated?
                    if ! git diff --quiet "$current_tag" "$last_tag" -- install/bash_completion.sh; then
                        CUI_displayMsg warning "Bash autocompletion updated. Please restart your Bash session or try: <b>source ~/.bashrc</b>";
                    fi

                    # Config file updated?
                    if ! git diff --quiet "$current_tag" "$last_tag" -- $TWGIT_CONF_DIR/twgit-dist.sh; then
                        echo
                        CUI_displayMsg warning "Config file updated! \
Please consider the following diff between old and new version of '<b>$TWGIT_CONF_DIR/twgit-dist.sh</b>', \
then consequently update '<b>$TWGIT_CONF_DIR/twgit.sh</b>':";
                        git diff "$current_tag" "$last_tag" -- $TWGIT_CONF_DIR/twgit-dist.sh
                        if [ "$(git config --get color.diff)" != 'always' ]; then
                            CUI_displayMsg help "Try this to get colored diff in this command: <b>git config --global color.diff always</b>"
                        fi
                    fi
                fi
            else
                CUI_displayMsg processing 'Twgit already up-to-date.'
            fi

            # Prochain update :
            CUI_displayMsg processing "Next auto-update check in $TWGIT_UPDATE_NB_DAYS days."
            touch "$TWGIT_UPDATE_PATH"

            # Invite :
            if [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
                if [ "$is_forced" = 0 ]; then
                    echo 'Continuing with your initial request...'
                    echo
                    cd - 1>/dev/null
                    $TWGIT_EXEC $*
                fi
                exit 0
            fi
        fi
    elif [ ! -z "$is_forced" ]; then
        CUI_displayMsg warning 'Git repositoy not found!'
    fi
    cd - 1>/dev/null
}
