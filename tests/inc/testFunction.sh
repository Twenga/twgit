#!/bin/bash

##
# Call a function of common.inc.sh after loading Shell config files.
# e.g.: /bin/bash testFunction.sh process_fetch x
#
# @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
#



# Parameters:
sCommonFunction="$1"; shift

# Includes:
. $(dirname $0)/../../conf/twgit.sh
. $TWGIT_INC_DIR/common.inc.sh
CUI_initColors

# Execution:
if [ ! -z "$sCommonFunction" ]; then
    $sCommonFunction "$@"
fi