#!/bin/bash

##
# twgit
#
# Copyright (c) 2011 Twenga SA.
#
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/
# or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
#
# @copyright 2011 Twenga SA
# @copyright 2012 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @license http://creativecommons.org/licenses/by-nc-sa/3.0/
#

. $TWGIT_INC_DIR/options_handler.inc.sh
. $TWGIT_INC_DIR/ui.inc.sh



#--------------------------------------------------------------------
# Functions "Get"
#--------------------------------------------------------------------

##
# Affiche les $1 derniers hotfixes (nom complet), à raison d'un par ligne.
#
# @param int $1 nombre des derniers hotfixes à afficher
#
function get_last_hotfixes () {
    git branch -r --no-color | grep $TWGIT_ORIGIN/$TWGIT_PREFIX_HOTFIX | sed 's/^[* ] //' | sort -n | tail -n $1
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
    git branch -r --no-color | sed 's/^[* ] //'
}

##
# Affiche la liste des branches distantes qui ne sont pas catégorisables dans le process.
#
function get_dissident_remote_branches () {
    git branch -r --no-color | sed 's/^[* ] //' \
        | grep -vP "^$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" \
        | grep -vP "^$TWGIT_ORIGIN/$TWGIT_PREFIX_RELEASE" \
        | grep -vP "^$TWGIT_ORIGIN/$TWGIT_PREFIX_HOTFIX" \
        | grep -vP "^$TWGIT_ORIGIN/$TWGIT_PREFIX_DEMO" \
        | grep -vP "^$TWGIT_ORIGIN/HEAD" \
        | grep -vP "^$TWGIT_ORIGIN/master" \
        | grep -vP "^$TWGIT_ORIGIN/$TWGIT_STABLE"
}

##
# Affiche le nom complet des releases distantes (avec "$TWGIT_ORIGIN/") non encore mergées à $TWGIT_ORIGIN/$TWGIT_STABLE, à raison d'une par ligne.
#
function get_releases_in_progress () {
    git branch -r --no-merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_RELEASE" | sed 's/^[* ]*//'
}

##
# Affiche le nom complet des releases non encore mergées à $TWGIT_ORIGIN/$TWGIT_STABLE, à raison d'une par ligne.
#
function get_hotfixes_in_progress () {
    git branch -r --no-merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_HOTFIX" | sed 's/^[* ]*//'
}

##
# Affiche la release distante courante (nom complet sans "$TWGIT_ORIGIN/"), c.-à-d. celle normalement unique à ne pas avoir été encore mergée à $TWGIT_ORIGIN/$TWGIT_STABLE.
# Chaîne vide sinon.
#
function get_current_release_in_progress () {
    local releases="$(get_releases_in_progress)"
    local release="$(echo $releases | tr '\n' ' ' | cut -d' ' -f1)"
    [[ $(echo $releases | wc -w) > 1 ]] && die "More than one release in propress detected: $(echo $releases | sed 's/ /, /g')! Only '$release' will be treated here."
    echo ${release:((${#TWGIT_ORIGIN}+1))}	# supprime le préfixe 'origin/'
}

##
# Calcule la liste locale des features distantes (nom complet avec "$TWGIT_ORIGIN/") mergées à la release distante $1,
# sur une seule ligne séparées par des espaces,
# et enregistre le résultat dans la globale GET_MERGED_FEATURES_RETURN_VALUE afin d'éviter les subshells.
#
# @param string $1 nom complet d'une release distante, sans "$TWGIT_ORIGIN/"
#
function get_merged_features () {
    local release="$1"

    get_git_merged_branches $TWGIT_ORIGIN/$release
    local merged_branches="${MERGED_BRANCHES[$TWGIT_ORIGIN/$release]}"

    local features="$(echo "$merged_branches" | grep $TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g')"

    get_features merged $release
    local features_v2="$GET_FEATURES_RETURN_VALUE"

    [ "$features" != "$features_v2" ] && die "Inconsistent result about merged features: '$features' != '$features_v2'!"
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
#
function get_git_rev_parse () {
    local key="$1"
    if [ -z "${REV_PARSE[$key]}" ]; then
        REV_PARSE[$key]="$(git rev-parse $key)"
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
# @see MERGE_BASE
#
function get_git_merge_base () {
    local rev1="$1"
    local rev2="$2"
    local key="$rev1|$rev2"
    if [ -z "${MERGE_BASE[$key]}" ]; then
        MERGE_BASE[$key]="$(git merge-base $rev1 $rev2)"
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
#
function get_git_merged_branches () {
    local rev="$1"
    if [ -z "${MERGED_BRANCHES[$rev]}" ]; then
        MERGED_BRANCHES[$rev]="$(git branch -r --merged $rev)"
    fi
}

##
# Calcule la liste des features (nom complet) de relation de type $1 avec la release distante $2,
# sur une seule ligne séparées par des espaces, et enregistre le résultat dans la globale GET_FEATURES_RETURN_VALUE
# afin d'éviter les subshells.
#
# @param string $1 Type de relation avec la release $2 :
#    - 'merged' pour lister les features mergées dans la release $2 et restées telle quelle depuis.
#    - 'merged_in_progress' pour lister les features mergées dans la release $2 et dont le développement à continué.
#    - 'free' pour lister celles n'ayant aucun rapport avec la release $2
# @param string $2 nom complet d'une release distante, sans "$TWGIT_ORIGIN/"
#
function get_features () {
    local feature_type="$1"
    local release="$2"

    if [ -z "$release" ]; then
        if [ "$feature_type" = 'merged' ] || [ "$feature_type" = 'merged_in_progress' ]; then
            GET_FEATURES_RETURN_VALUE=''
        elif [ "$feature_type" = 'free' ]; then
            GET_FEATURES_RETURN_VALUE="$(git branch -r --no-merged $TWGIT_ORIGIN/$TWGIT_STABLE | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//' | tr '\n' ' ' | sed 's/ *$//g')"
        fi
    else
        release="$TWGIT_ORIGIN/$release"
        local return_features=''
        local features=$(git branch -r | grep "$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE" | sed 's/^[* ]*//')

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

            get_git_merge_base $release_rev $f_rev
            release_merge_base="${MERGE_BASE[$release_rev|$f_rev]}"

            if [ "$release_merge_base" = "$f_rev" ] && [ -n "$(echo "$merged_branches" | grep $f)" ]; then
                [ "$feature_type" = 'merged' ] && return_features="$return_features $f"
            else
                get_git_merge_base $release_merge_base $head_rev
                stable_merge_base="${MERGE_BASE[$release_merge_base|$head_rev]}"

                #has_dependency="$(git rev-list $f_rev ^$release_merge_base --parents --merges | grep $release_merge_base | wc -l)"
                if [ "$release_merge_base" != "$stable_merge_base" ] && \
                        [ "$(git rev-list $f_rev ^$release_merge_base --parents --merges | grep $release_merge_base | wc -l)" -eq 0 ]; then
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
    git tag | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/v//' | sed 's/\./;/g' | sort --field-separator=";" -k1n -k2n -k3n | sed 's/;/./g' | sed 's/^/v/' | tail -n $n
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
        tag_rev=$(git rev-list $t | head -n 1)
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

    GET_TAGS_NOT_MERGED_INTO_BRANCH_RETURN_VALUE="${tags_not_merged:1}"
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
# Calcul et retourne la liste des emails des N committeurs les plus significatifs (en nombre de commits)
# de la branche distante spécifiée, à raison d'un par ligne.
# Filtre les committeurs sans email ainsi que 'devaa@twenga.com'.
#
# @param string $1 nom complet de branche distante, sans le "$TWGIT_ORIGIN/"
# @param int $2 nombre maximum de committers à afficher
# @see display_rank_contributors()
#
function get_contributors () {
    local branch="$TWGIT_ORIGIN/$1"
    local max="$2"
    git shortlog -nse $TWGIT_ORIGIN/$TWGIT_STABLE..$branch \
        | grep -E "@$TWGIT_EMAIL_DOMAIN_NAME>$" \
        | head -n $max | sed -r "s/^.*? <(.*@$TWGIT_EMAIL_DOMAIN_NAME)>$/\1/"
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
#
function getFeatureSubject () {
    local short_name="$1"
    local subject

    [ ! -s "$TWGIT_FEATURES_SUBJECT_PATH" ] && touch "$TWGIT_FEATURES_SUBJECT_PATH"

    subject="$(cat "$TWGIT_FEATURES_SUBJECT_PATH" | grep -E "^$short_name;" | head -n 1 | sed 's/^[^;]*;//')"
    if [ -z "$subject" ] && [ ! -z "$TWGIT_FEATURE_SUBJECT_CONNECTOR" ]; then
        local connector="$(printf "$TWGIT_FEATURE_SUBJECT_CONNECTOR_PATH" "$TWGIT_FEATURE_SUBJECT_CONNECTOR")"
        if [ ! -f "$connector" ]; then
            warn "'$TWGIT_FEATURE_SUBJECT_CONNECTOR' connector not found!"
        else
            subject="$(. $connector $short_name 2>/dev/null)"
            if [ $? -ne 0 ]; then
                error "'$TWGIT_FEATURE_SUBJECT_CONNECTOR' connector failed!"
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
    if ! git config --global user.name 1>/dev/null; then
        die "Unknown user.name! Please, do: git config --global user.name 'Firstname Lastname'"
    elif ! git config --global user.email 1>/dev/null; then
        die "Unknown user.email! Please, do: git config --global user.email 'firstname.lastname@twenga.com'"
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

    if [ "$(git remote | grep -R "^$TWGIT_ORIGIN$" | wc -l)" -ne 1 ]; then
        die "No remote '$TWGIT_ORIGIN' repository specified! Try: 'git remote add $TWGIT_ORIGIN <url>'"
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
# S'assure que les 2 branches spécifiées sont au même niveau.
# Gère l'option '-I' permettant de répondre automatiquement (mode non interactif) oui à la demande de pull.
#
# @param string $1 nom complet d'une branche locale
# @param string $2 nom complet d'une branche distante
#
function assert_branches_equal () {
    processing "Compare branches '$1' with '$2'..."
    if ! has $1 $(get_local_branches); then
        die "Local branch '$1' does not exist and is required!"
    elif ! has $2 $(get_remote_branches); then
        die "Remote branch '$2' does not exist and is required!"
    fi

    compare_branches "$1" "$2"
    local status=$?
    if [ $status -gt 0 ]; then
        warn "Branches '$1' and '$2' have diverged."
        if [ $status -eq 1 ]; then
            warn "And local branch '$1' may be fast-forwarded!"
            if ! isset_option 'I'; then
                echo -n $(question "Pull '$1'? [Y/N] "); read answer
                [ "$answer" != "Y" ] && [ "$answer" != "y" ] && die "Pull aborted! You must make a 'git pull $TWGIT_ORIGIN $1' to continue."
            fi
            exec_git_command "git checkout $1" "Checkout '$1' failed!"
            exec_git_command "git merge $2" "Update '$1' failed!"
        elif [ $status -eq 2 ]; then
            # Warn here (not die), since there is no harm in being ahead:
            warn "And local branch '$1' is ahead of '$2'."
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
    processing 'Check local branches...'
    if has $branch $(get_local_branches); then
        processing "Local branch '$branch' already exists!"
        if ! has "$TWGIT_ORIGIN/$branch" $(get_remote_branches); then
            error "Remote feature '$TWGIT_ORIGIN/$branch' not found while local one exists!"
            help 'Perhaps:'
            help_detail "- check the name of your branch"
            help_detail "- delete this out of process local branch: git branch -D $branch"
            help_detail "- or force renewal if feature: twgit feature start -d xxxx"
        else
            exec_git_command "git checkout $branch" "Could not checkout '$branch'!"

            # Informe de la fraîcheur de la branche :
            compare_branches "$branch" "$TWGIT_ORIGIN/$branch"
            local status=$?
            if [ $status -eq 0 ]; then
                help "Local branch '$branch' up-to-date with remote '$TWGIT_ORIGIN/$branch'."
            elif [ $status -eq 1 ]; then
                help "If need be: git merge $TWGIT_ORIGIN/$branch"
            elif [ $status -eq 2 ]; then
                help "If need be: git push $TWGIT_ORIGIN $branch"
            else
                warn "Branches '$branch' and '$TWGIT_ORIGIN/$branch' have diverged!"
            fi

            alert_old_branch "$TWGIT_ORIGIN/$branch" 'with-help'
        fi
        echo
        exit 0
    fi
}

##
# S'assure que le dépôt git courant est dans le status 'working directory clean'.
#
function assert_clean_working_tree () {
    processing 'Check clean working tree...'
    if [ `git status --porcelain --ignore-submodules=all | wc -l` -ne 0 ]; then
        error 'Untracked files or changes to be committed in your working tree!'
        exec_git_command 'git status' 'Git status failed!'
        exit 1
    fi
}

##
# S'assure que la référence fournie est un nom syntaxiquement correct de branche potentielle.
#
# @param string $1 référence de branche
#
function assert_valid_ref_name () {
    processing 'Check valid ref name...'
    git check-ref-format --branch "$1" 1>/dev/null 2>&1
    if [ $? -ne 0 ]; then
        die "'$1' is not a valid reference name!"
    elif  echo "$1" | grep -q ' '; then
        die "'$1' is not a valid reference name: whitespaces not allowed!"
    fi

    echo $1 | grep -vP "^$TWGIT_PREFIX_FEATURE" \
        | grep -vP "^$TWGIT_PREFIX_RELEASE" \
        | grep -vP "^$TWGIT_PREFIX_HOTFIX" \
        | grep -vP "^$TWGIT_PREFIX_DEMO" 1>/dev/null
    if [ $? -ne 0 ]; then
        die 'Unauthorized reference prefix! Pick another name.'
    fi
}

##
# S'assure que la référence fournie est un nom syntaxiquement correct de tag potentiel et qu'il est disponible.
#
# @param string $1 référence de tag au format court \d+.\d+.\d+
#
function assert_valid_tag_name () {
    local tag="$1"
    assert_valid_ref_name "$tag"
    processing 'Check valid tag name...'
    $(echo "$tag" | grep -qP '^'$TWGIT_PREFIX_TAG'[0-9]+\.[0-9]+\.[0-9]+$') || die "Unauthorized tag name: '$tag'!"
    processing "Check whether tag '$tag' already exists..."
    has "$tag" $(get_all_tags) && die "Tag '$tag' already exists! Try: twgit tag list"
}

##
# S'assure que l'on ne tente pas de supprimer une branche sur laquelle on se trouve (checkout),
# auquel cas on checkout sur $TWGIT_STABLE.
#
# @param string $1 nom complet de la branche locale en instance de suppression
#
function assert_working_tree_is_not_on_delete_branch () {
    local branch="$1"
    processing "Check current branch..."
    if [ "$(get_current_branch)" = "$branch" ]; then
        processing "Cannot delete the branch '$branch' which you are currently on! So:"
        exec_git_command "git checkout $TWGIT_STABLE" "Could not checkout '$TWGIT_STABLE'!"
    fi
}

##
# S'assure qu'au moins un tag existe.
#
function assert_tag_exists () {
    processing 'Get last tag...'
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
        error "Please update git! Current: $(git --version | sed 's/[^0-9.]//g'). Need $1 or newer."
        help 'Try:'
        help_detail 'sudo apt-add-repository ppa:git-core/ppa'
        help_detail 'sudo apt-get update'
        help_detail 'sudo apt-get install git'
        echo
        exit
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
        if [ ! -z "$option" ]; then
            echo
        fi
    fi
}

##
# Réalise un commit "blanc" permettant de dégager la référence de la branche courante de celle dont elle est issue.
# Dit autrement, la première ne sera plus un ancêtre de la seconde.
#
# @param string $1 titre à inclure dans le message de commit
# @param string $2 nom complet de la branche à décaler
# @see $TWGIT_FIRST_COMMIT_MSG
#
function process_first_commit () {
    local commit_msg=$(printf "$TWGIT_FIRST_COMMIT_MSG" "$1" "$2")
    processing "${TWGIT_GIT_COMMAND_PROMPT}git commit --allow-empty -m \"$commit_msg\""
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
#
function exec_git_command () {
    local cmd="$1"
    local error_msg="$2"
    processing "$TWGIT_GIT_COMMAND_PROMPT$cmd"
    $cmd || die "$error_msg"
}

##
# Supprime la branche locale spécifiée.
#
# @param string $1 nom complet de la branche locale
#
function remove_local_branch () {
    local branch="$1"
    if has $branch $(get_local_branches); then
        exec_git_command "git branch -D $branch" "Remove local branch '$branch' failed!"
    else
        processing "Local branch '$branch' not found."
    fi
}

##
# Supprime la branche distante spécifiée.
#
# @param string $1 nom de la branche distante sans le '$TWGIT_ORIGIN/'
#
function remove_remote_branch () {
    local branch="$1"
    if has "$TWGIT_ORIGIN/$branch" $(get_remote_branches); then
        exec_git_command "git push $TWGIT_ORIGIN :$branch" "Delete remote branch '$TWGIT_ORIGIN/$branch' failed!"
        if [ $? -ne 0 ]; then
            processing "Remove remote branch '$TWGIT_ORIGIN/$branch' failed! Maybe already deleted... so:"
            exec_git_command "git remote prune $TWGIT_ORIGIN" "Prune failed!"
        fi
    else
        die "Remote branch '$TWGIT_ORIGIN/$branch' not found!"
    fi
}

##
# Supprime la branche locale et distante de la feature spécifiée.
#
# @param string $1 nom court de la feature
#
function remove_feature () {
    local feature="$1"
    local feature_fullname="$TWGIT_PREFIX_FEATURE$feature"

    assert_valid_ref_name $feature
    assert_clean_working_tree
    assert_working_tree_is_not_on_delete_branch $feature_fullname

    process_fetch
    remove_local_branch $feature_fullname
    remove_remote_branch $feature_fullname
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
    processing "${TWGIT_GIT_COMMAND_PROMPT}git tag -a $tag_fullname -m \"${TWGIT_PREFIX_COMMIT_MSG}$commit_msg\""
    git tag -a $tag_fullname -m "${TWGIT_PREFIX_COMMIT_MSG}$commit_msg" || die "Could not create tag '$tag_fullname'!"

    # Push tags:
    exec_git_command "git push --tags $TWGIT_ORIGIN $TWGIT_STABLE" "Could not push '$TWGIT_STABLE' on '$TWGIT_ORIGIN'!"
}



#--------------------------------------------------------------------
# Autres fonctions...
#--------------------------------------------------------------------

##
# Echappe les caractères '.+$*' d'une chaîne.
#
# @param string $1 chaîne à échapper
#
function escape () {
    echo "$1" | sed 's/\([\.\+\$\*]\)/\\\1/g'
}

##
# Retourne 0 si la chaîne $1 est présente dans la concaténation du reste des paramètres, 1 sinon.
#
# @param string $1 chaîne à rechercher
# @param string $2-n chaînes dans lesquelles rechercher
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
# @param string $1 type type de branches affichées, parmi {'feature', 'release', 'hotfix'}
# @param string $2 liste des branches à présenter, à raison d'une par ligne, au format 'origin/xxx'
#
function display_branches () {
    local type="$1"
    local branches="$2"
    local -A titles=(
        [feature]='Feature: '
        [release]='Release: '
        [hotfix]='Hotfix: '
    )

    if [ -z "$branches" ]; then
        info 'No such branch exists.';
    else
        local prefix="$TWGIT_ORIGIN/$TWGIT_PREFIX_FEATURE"
        local add_empty_line=0
        for branch in $branches; do
            if ! isset_option 'c'; then
                [ "$add_empty_line" = "0" ] && add_empty_line=1 || echo
            fi
            echo -n $(info "${titles[$type]}$branch ")

            [ "$type" = "feature" ] && displayFeatureSubject "${branch:${#prefix}}" || echo

            alert_old_branch "$branch"

            # Afficher les informations de commit :
            ! isset_option 'c' && git show $branch --pretty=medium | grep -v '^Merge: ' | head -n 3
        done
    fi
}

##
# Affiche un warning si des tags ne sont pas présents dans la branche spécifiée.
#
# @param string $1 nom complet de la branche, locale ou distante
# @param string $2 si présent et vaut 'with-help', alors une suggestion de merge sera proposée
#
function alert_old_branch () {
    get_tags_not_merged_into_branch "$1"
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
        [ "$2" = 'with-help' ] && msg="${msg} If need be: git merge --no-ff $(get_last_tag)"
        warn "$msg"
    fi
}

##
# Affiche un interval "a to z" à partir du premier et du dernier élément de la liste fournie.
#
# @param string $1 liste de valeurs séparées par des espaces
#
function displayInterval () {
    local -a list=($@)
    local nb_items="${#list[@]}"
    local first_item="${list[0]}"
    local last_item="${list[$((nb_items-1))]}"

    echo -n "'<b>$first_item</b>'"
    [ "$nb_items" -gt 1 ] && echo " to '<b>$last_item</b>'" || echo
}

##
# Affiche la liste de valeurs sur une seule ligne, séparées par des virgules et chaque valeur entre simples quotes.
#
# @param string $@ liste de valeurs sur une ou plusieurs lignes, séparées par des espaces ou des sauts de ligne
#
function displayQuotedEnum () {
    local list="$@"
    local one_line_list="$(echo $list | tr '\n' ' ')"
    local trimmed_list="$(echo $one_line_list)"
    local quoted_list="'<b>${trimmed_list// /</b>', '<b>}</b>'"
    echo $quoted_list
}

##
# Affiche le sujet d'une feature (ticket Redmine, issue Github, ...)
# Le premier appel sollicite ws_redmine.inc.php qui lui-même exploite un WS Redmine,
# les suivants bénéficieront du fichier de cache $TWGIT_FEATURES_SUBJECT_PATH.
#
# @param int $1 nom court de la feature
# @see getFeatureSubject()
#
function displayFeatureSubject () {
    local subject="$(getFeatureSubject "$1")"
    [ ! -z "$subject" ] && displayMsg feature_subject "$subject" || echo
}

##
# Convertit une liste de valeurs en une ligne CSV au format suivant et l'affiche : "v1";"va""lue2";"v\'3"
#
# @param string $@ liste de valeurs
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
# Propose de supprimer une à une les branches qui ne sont plus trackées.
#
function clean_branches () {
    local tracked="$(git fetch --all -v --dry-run 2>&1 | grep '\->' | sed -r 's/^.* +([^ ]+) +\-> +.*$/\1/')"
    local locales="$(get_local_branches)"
    for branch in $locales; do
        if ! has $branch $tracked; then
            echo -n $(question "Local branch '$branch' is not tracked. Remove? [Y/N] ")
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
# @param string $2 optional url of remote repository. Used only if not already setted.
# @testedby TwgitMainTest
#
function init () {
    process_options "$@"
    require_parameter 'tag'
    local tag="$RETVAL"
    local remote_url="$2"
    local tag_fullname="$TWGIT_PREFIX_TAG$tag"

    processing "Check need for git init..."
    if [ ! -z "$(git rev-parse --git-dir 2>&1 1>/dev/null)" ]; then
        exec_git_command 'git init' 'Initialization of git repository failed!'
    else
        assert_clean_working_tree
    fi

    assert_valid_tag_name $tag_fullname

    processing "Check presence of remote '$TWGIT_ORIGIN' repository..."
    if [ "$(git remote | grep -R "^$TWGIT_ORIGIN$" | wc -l)" -ne 1 ]; then
        [ -z "$remote_url" ] && die "Remote '$TWGIT_ORIGIN' repository url required!"
        exec_git_command "git remote add origin $remote_url" 'Add remote repository failed!'
    fi
    process_fetch

    processing "Check presence of '$TWGIT_STABLE' branch..."
    if has $TWGIT_STABLE $(get_local_branches); then
        processing "Local '$TWGIT_STABLE' detected."
        if ! has $TWGIT_ORIGIN/$TWGIT_STABLE $(get_remote_branches); then
            exec_git_command "git push --set-upstream $TWGIT_ORIGIN $TWGIT_STABLE" 'Git push failed!'
        fi
    elif has $TWGIT_ORIGIN/$TWGIT_STABLE $(get_remote_branches); then
        processing "Remote '$TWGIT_ORIGIN/$TWGIT_STABLE' detected."
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

    create_and_push_tag "$tag_fullname" "First tag."
}

##
# Affiche la liste des emails des N committeurs les plus significatifs (en nombre de commits)
# de la branche distante spécifiée, à raison d'un par ligne.
# Filtre les committeurs sans email ainsi que 'devaa@twenga.com'.
#
# @param string $1 nom complet de branche distante, sans le "$TWGIT_ORIGIN/"
# @param int $2 nombre maximum de committers à afficher, optionnel (vaut $TWGIT_DEFAULT_NB_COMMITTERS par défaut)
#
function display_rank_contributors () {
    local branch_fullname="$1"
    local max="$2"
    [ -z "$max" ] && max=$TWGIT_DEFAULT_NB_COMMITTERS

    info "First $max committers into '$TWGIT_ORIGIN/$branch_fullname' remote branch:"
    local contributors="$(get_contributors "$branch_fullname" $max)"
    [ -z "$contributors" ] && echo 'nobody' || echo $contributors | tr ' ' '\n'
    echo
}

##
# Permet la mise à jour automatique de l'application dans le cas où le .git est toujours présent.
# Tous les $TWGIT_UPDATE_NB_DAYS jours un fetch sera exécuté afin de proposer à l'utilisateur une
# éventuelle MAJ. Qu'il décline ou non, le prochain passage aura lieu dans à nouveau $TWGIT_UPDATE_NB_DAYS jours.
#
# A des fins de test : "touch -mt 1105200101 ~/twgit/.lastupdate"
#
# @param string $1 Si non vide, force la vérification de la présence d'une MAJ même si $TWGIT_UPDATE_NB_DAYS jours
#    ne se sont pas écoulés depuis le dernier test.
#
function autoupdate () {
    local is_forced="$1"
    cd "$TWGIT_ROOT_DIR"
    if git rev-parse --git-dir 1>/dev/null 2>&1; then
        [ ! -f "$TWGIT_UPDATE_PATH" ] && touch "$TWGIT_UPDATE_PATH"
        local elapsed_time=$(( ($(date -u +%s) - $(date -r "$TWGIT_UPDATE_PATH" +%s)) ))
        local interval=$(( $TWGIT_UPDATE_NB_DAYS * 86400 ))
        local answer=''

        if [ "$elapsed_time" -gt "$interval" ] || [ ! -z "$is_forced" ]; then
            # Update Git :
            processing "Fetch twgit repository for auto-update check..."
            git fetch

            assert_tag_exists
            local current_tag="$(git describe)"
            local last_tag="$(get_last_tag)"
            if [ "$current_tag" != "$last_tag" ]; then
                echo -n $(question "Update $last_tag available! Do you want to update twgit (or manually: twgit update)? [Y/N] ")
                read answer
                if [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
                    processing 'Update in progress...'
                    exec_git_command 'git reset --hard' 'Hard reset failed!'
                    exec_git_command "git checkout tags/$last_tag" "Could not check out tag '$last_tag'!"
                    > "$TWGIT_FEATURES_SUBJECT_PATH"
                fi
            else
                processing 'Twgit already up-to-date.'
            fi

            # Prochain update :
            processing "Next auto-update check in $TWGIT_UPDATE_NB_DAYS days."
            touch "$TWGIT_UPDATE_PATH"

            # MAJ du système d'update d'autocomplétion :
            if [ ! -h "/etc/bash_completion.d/twgit" ]; then
                warn "New autocompletion update system request you execute just once this line (to adapt):"
                help_detail "sudo rm /etc/bash_completion.d/twgit && sudo ln -s ~/twgit/install/.bash_completion /etc/bash_completion.d/twgit && source ~/.bashrc"
            fi

            # Invite :
            if [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
                [ -z "$is_forced" ] && echo 'Thank you for re-entering your request.'
                exit 0
            fi
        fi
    elif [ ! -z "$is_forced" ]; then
        warn 'Git repositoy not found!'
    fi
    cd - 1>/dev/null
}
