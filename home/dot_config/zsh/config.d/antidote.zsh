# Make plugin folder names pretty
zstyle ':antidote:bundle' use-friendly-names 'yes'

# Disable in favour of auto_title.zsh which uses shrink_path
typeset -g DISABLE_AUTO_TITLE=true

# Source and load plugins found in ${ZDOTDIR}/.zsh_plugins.txt
source $ZDOTDIR/antidote/antidote.zsh

# Load Antidote
antidote load
