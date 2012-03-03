#!/bin/bash

##
# Call a function of common.inc.sh.
#
# @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
#



# Parameters:
sCommonFunction="$1"; shift

# Includes:
. `dirname $0`/../../conf/config.inc.sh
. $TWGIT_INC_DIR/common.inc.sh

# Execution:
if [ ! -z "$sCommonFunction" ]; then
    $sCommonFunction "$@"
fi