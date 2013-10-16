#!/bin/bash

##
# Call a function of common.inc.sh after loading Shell config files.
# e.g.: /bin/bash testFunction.sh process_fetch x
#
# @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
#



# Parameters:
sCommonFunction="$1"; shift

# Pre config:
# Absolute path of the top-level directory of the current user repository:
TWGIT_USER_REPOSITORY_ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null)"

# Includes:
. $(dirname $0)/../../conf/twgit.sh
. $TWGIT_INC_DIR/common.inc.sh

# Post config:
# TWGIT_USER_REPOSITORY_ROOT_DIR is absolute path of the top-level directory of the current user repository
TWGIT_FEATURES_SUBJECT_PATH="$TWGIT_USER_REPOSITORY_ROOT_DIR/$TWGIT_FEATURES_SUBJECT_FILENAME"

# Execution:
if [ ! -z "$sCommonFunction" ]; then
    $sCommonFunction "$@"
fi
