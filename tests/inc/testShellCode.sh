#!/bin/bash

##
# Call a function of common.inc.sh.
#
# @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
#



# Parameters:
sCmds="$1"; shift

# Includes:
. $(dirname $0)/../../conf/twgit.sh
. $TWGIT_INC_DIR/common.inc.sh

# Execution:
rFile="$(tempfile)"
echo "$sCmds" > $rFile
. $rFile
rm -f $rFile