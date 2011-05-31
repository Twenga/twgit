#!/bin/sh

## Optionizer 1.1 sh revision tony.caron
last_option=NULL;
for option in "$@"
do
    if [ "${option:0:2}" == "--" ]; then
      last_option=${option}
      eval opt_${last_option/'--'}=1
	elif [ "${last_option}" ]; then
         eval opt_${last_option/'--'}='"${option}"'
    fi
done

if [ ! "$opt_branch"  ]; then
	echo "You must specify a branch ID"
	exit
fi

git_get_conflict_files()
{
	git status | grep 'both added' | sed 's/ //g' | cut -d ':' -f 2
}

GIT_BIN=/usr/local/bin/git
export PATH=/usr/local/libexec/gitw/:$PATH

TS=`date +'%Y%m%d%H%M%S'`
LOGFILE="/tmp/tonylog"

exec 2>$LOGFILE
clear
#exec 1>$LOGFILE"3"

#Merge de(s) branche(s) distante sur la release local
reverse=""
for remote_branch in $opt_branch
do
	echo  -n "Trying to merge $remote_branch... "
	reverse=remote_branch $reverse
	if ! $GIT_BIN merge --no-ff "origin/"$remote_branch >> $LOGFILE  ; then
		file=$(git_get_conflict_files)
		echo "[FAIL] on file(s): "$file

		#git diff $file
		#git blame $file

		git reset --hard >> $LOGFILE
		#git reset --hard origin/release
		#exit
	else
		echo "[OK]"
	fi
done
