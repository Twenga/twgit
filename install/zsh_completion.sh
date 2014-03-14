# COMPLETION SETTINGS
# add custom completion scripts
current_path=$PWD
fpath=($current_path/zsh $fpath) 
 
# compsys initialization
autoload -U compinit
compinit
 
# show completion menu when number of options is at least 2
zstyle ':completion:*' menu select=2
