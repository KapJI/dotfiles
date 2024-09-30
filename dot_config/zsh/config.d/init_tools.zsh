# Enable powerlevel10k
POWERLEVEL9K_MODE='nerdfont-complete'
source "$ZDOTDIR/config.d/plugins/p10k.zsh"

# Enable Iterm2 shell integration
source "$ZDOTDIR/config.d/plugins/iterm2_shell_integration.zsh"

# Setup The Fuck
eval $(thefuck --alias)

# Enable broot
source ${HOME}/.config/broot/launcher/bash/br
