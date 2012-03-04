function parse_git_branch {
    git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

function parse_git_status {
    noupdated=`git status --porcelain 2> /dev/null | grep -E "^ (M|D)" | wc -l`
    nocommitted=`git status --porcelain 2> /dev/null | grep -E "^(M|A|D|R|C)" | wc -l`

    if [[ $noupdated -gt 0 ]]; then echo -n "*"; fi
    if [[ $nocommitted -gt 0 ]]; then echo -n "+"; fi
}

RED="\[\033[01;31m\]"
YELLOW="\[\033[01;33m\]"
GREEN="\[\033[01;32m\]"
BLUE="\[\033[01;34m\]"
NC="\[\033[0m\]"

case $TERM in
    xterm*)
        TITLEBAR='\[\e]0;\u@\h: \w\a\]';
        ;;
    *)
        TITLEBAR="";
        ;;
esac

PS1="${TITLEBAR}$RED\$(date +%H:%M) $GREEN\u@\h $BLUE\w$YELLOW\$(parse_git_branch)\$(parse_git_status) $BLUE\$ $NC"
