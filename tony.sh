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

## LIB ##
git_branch_exists() {
        has $1 $(git_all_branches)
}

git_local_branch_exists() {
        has $1 $(git_local_branches)
}

git_remote_branch_exists() {
        has "origin/"$1 $(git_remote_branches)
}

git_current_branch() {
        git branch --no-color | grep '^\* ' | grep -v 'no branch' | sed 's/^* //g'
}


git_all_branches() { ( git branch --no-color; git branch -r --no-color) | sed 's/^[* ] //'; }
git_local_branches() { git branch --no-color | sed 's/^[* ] //'; }
git_remote_branches() { git branch -r --no-color | sed 's/^[* ] //'; }

git_switch_to_branch(){
	if [ $(git_current_branch) != "$1" ]; then
		git checkout $1
	fi
}

git_get_conflict_files()
{
	git status | grep 'both added' | sed 's/ //g' | cut -d ':' -f 2
}



# set logic
has() {
        local item=$1; shift
        echo " $@ " | grep -q " $(escape $item) "
}

# shell output
warn() { echo "$@" >&2; }
die() { warn "$@"; exit 1; }

escape() {
        echo "$1" | sed 's/\([\.\+\$\*]\)/\\\1/g'
}


cd demo

GIT_BIN=/usr/local/bin/git
export PATH=/usr/local/libexec/gitw/:$PATH


#deploiement sur QA

TS=`date +'%Y%m%d%H%M%S'`
LOGFILE="/tmp/tonylog"

exec 2>$LOGFILE
clear
#exec 1>$LOGFILE"3"

#Creation d'une branch release distante depuis la master_prod #### todo prendre la master_prod
#$GIT_BIN push origin master:$TS

for remote_branch in $opt_branch
do
	if ! git_remote_branch_exists "$remote_branch"; then
		die "Remote branch $remote_branch doesn't exist"
	fi
done

#Delete de la branch release locale
if git_local_branch_exists "release"; then
	echo "Delete local Release branch..."
	git_switch_to_branch master
	git branch -D "release"   >> $LOGFILE
fi

#Delete de la branch release distante
if git_remote_branch_exists "release"; then
    echo "Delete remote Release branch..."
	git_switch_to_branch master
	#git push origin :release
	git branch -r -d origin/release >> $LOGFILE
	
	#$GIT_BIN branch -d "release" || \
	#	die "Could not delete the local branch release"
fi

#Creation d'une branch release distante
echo "Create Release branch..."
if git push origin master:release; then
	#Récupération en local + link
	git checkout --track  -f -b release origin/release >> $LOGFILE
	###### Try -f pour virer les untracket
fi

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
