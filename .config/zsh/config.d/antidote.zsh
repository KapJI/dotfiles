# Download plugin manager if we don't have it
if ! [[ -e $ZDOTDIR/antidote ]]
then
    git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/antidote
fi

# Make plugin folder names pretty
zstyle ':antidote:bundle' use-friendly-names 'yes'

# Source and load plugins found in ${ZDOTDIR}/.zsh_plugins.txt
source $ZDOTDIR/antidote/antidote.zsh

# Enable custom completion
fpath=("$HOME/.zsh_completion" $fpath)

# Load Antidote
antidote load
