#!/bin/bash

##
# Execute code calling functions of common.inc.sh after loading Shell config files.
# e.g.: /bin/bash testShellCode.sh 'process_options x -aV; isset_option a; echo $?'
#
# @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
# @author Laurent Toussaint <lt.laurent.toussaint@gmail.com>
#



# Parameters:
sCmds="$1"; shift

# Pre config:
# Absolute path of the top-level directory of the current user repository:
TWGIT_USER_REPOSITORY_ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null)"

# Includes:
. /tmp/conf-twgit.sh
. $TWGIT_INC_DIR/common.inc.sh

# Post config:
# TWGIT_USER_REPOSITORY_ROOT_DIR is absolute path of the top-level directory of the current user repository
TWGIT_FEATURES_SUBJECT_PATH="$TWGIT_USER_REPOSITORY_ROOT_DIR/$TWGIT_FEATURES_SUBJECT_FILENAME"

# Execution:
rFile="${TWGIT_TMP_DIR}/file.$$.$RANDOM"
echo "$sCmds" > $rFile
. $rFile
rm -f $rFile
