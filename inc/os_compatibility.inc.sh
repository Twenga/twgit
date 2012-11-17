#--------------------------------------------------------------------
# Mac OS X compatibility layer
#--------------------------------------------------------------------

# Witch OS:
uname="$(uname)"
if [ "$uname" = 'FreeBSD' ] || [ "$uname" = 'Darwin' ]; then
    TWGIT_OS='MacOSX'
else
    TWGIT_OS='Linux'
fi

##
# Display the last update time of specified path, in seconds since 1970-01-01 00:00:00 UTC.
# Compatible Linux and Mac OS X.
#
# @param string $1 path
# @see $TWGIT_OS
#
function getLastUpdateTimestamp () {
    local path="$1"
    if [ "$TWGIT_OS" = 'MacOSX' ]; then
        stat -f %m "$path"
    else
        date -r "$path" +%s
    fi
}

##
# Display the specified timestamp converted to date with "+%Y-%m-%d %T" format.
# Compatible Linux and Mac OS X.
#
# @param int $1 timestamp
# @see $TWGIT_OS
#
function getDateFromTimestamp () {
    local timestamp="$1"
    if [ "$TWGIT_OS" = 'MacOSX' ]; then
        date -r "$timestamp" "+%Y-%m-%d %T"
    else
        date --date "1970-01-01 $timestamp sec" "+%Y-%m-%d %T"
    fi
}

##
# Execute sed with the specified regexp-extended pattern.
# Compatible Linux and Mac OS X.
#
# @param string $1 pattern using extended regular expressions
# @see $TWGIT_OS
#
function sedRegexpExtended () {
    local pattern="$1"
    if [ "$TWGIT_OS" = 'MacOSX' ]; then
        sed -E "$pattern";
    else
        sed -r "$pattern";
    fi
}