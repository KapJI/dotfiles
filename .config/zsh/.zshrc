source "$ZDOTDIR/config.d/detect_os.zsh"

# Set PATH, should come before tmux attach.
source "$ZDOTDIR/config.d/path.zsh"

# Create ssh and vscode sockets before tmux.
source "$ZDOTDIR/config.d/sockets.zsh"

# Auto attach to tmux session. Should come before instant prompt.
source "$ZDOTDIR/config.d/tmux_attach.zsh"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load plugins
source "$ZDOTDIR/config.d/antidote.zsh"

# Configure shell
source "$ZDOTDIR/config.d/aliases.zsh"
source "$ZDOTDIR/config.d/completion.zsh"
source "$ZDOTDIR/config.d/env.zsh"
source "$ZDOTDIR/config.d/fb.zsh"
source "$ZDOTDIR/config.d/history.zsh"
source "$ZDOTDIR/config.d/init_tools.zsh"
source "$ZDOTDIR/config.d/key_bindings.zsh"
source "$ZDOTDIR/config.d/options.zsh"
source "$ZDOTDIR/config.d/os_specific.zsh"

# Configure plugins and tools
source "$ZDOTDIR/config.d/plugins/autosuggest.zsh"
source "$ZDOTDIR/config.d/plugins/enhancd.zsh"
source "$ZDOTDIR/config.d/plugins/fzf.zsh"
source "$ZDOTDIR/config.d/plugins/omz.zsh"
source "$ZDOTDIR/config.d/plugins/nvm.zsh"
source "$ZDOTDIR/config.d/plugins/vi_mode.zsh"
source "$ZDOTDIR/config.d/plugins/ysu.zsh"
source "$ZDOTDIR/config.d/plugins/zoxide.zsh"

# Load local zshrc if exists
local_zshrc="${ZDOTDIR}/.zshrc.local"
if [[ -f $local_zshrc ]]; then
    source $local_zshrc
fi

# Make sure there are no errors on shell load.
true
