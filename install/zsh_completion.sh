# COMPLETION SETTINGS
# add custom completion scripts
fpath=($HOME/dev/twenga/twgit/install/completion/zsh $fpath) 
 
# compsys initialization
autoload -U compinit
compinit
 
# show completion menu when number of options is at least 2
zstyle ':completion:*' menu select=2
