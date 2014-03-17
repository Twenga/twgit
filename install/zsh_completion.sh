# COMPLETION SETTINGS
# add custom completion scripts
current_path=$PWD
mypath=$(readlink -f $0)
current_path=$(dirname "$mypath")
fpath=("${current_path}/completion/zsh" $fpath) 
export fpath
 
# compsys initialization
autoload -U compinit
compinit
 
# show completion menu when number of options is at least 2
zstyle ':completion:*' menu select=2
