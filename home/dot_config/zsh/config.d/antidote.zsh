# Make plugin folder names pretty
zstyle ':antidote:bundle' use-friendly-names 'yes'

# Source and load plugins found in ${ZDOTDIR}/.zsh_plugins.txt
source $ZDOTDIR/antidote/antidote.zsh

# Load Antidote
antidote load
