# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOS=true
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            centos)
                CENTOS=true
                ;;
            debian|ubuntu|pop)
                DEBIAN_BASED=true
                ;;
            *)
                echo "ERROR: running on unknown Linux distro: ${ID}!"
                ;;
        esac
    else
        echo "ERROR: can't detect Linux distro!"
    fi
else
    echo "ERROR: running on unknown OS: ${OSTYPE}!"
fi

# Environment vars
# Used by $PATH
if [ "$MACOS" = true ]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi
export GOPATH=$(go env GOPATH)

# Set $PATH
# Should come before running tmux
_EXTRA_PATH="$GOPATH/bin:$HOME/bin:$HOME/.local/bin"
_EXTRA_PATH="$_EXTRA_PATH:/usr/local/bin:$HOME/.npm/bin:$HOME/.iterm2"
_EXTRA_PATH="$_EXTRA_PATH:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin"
if [ "$MACOS" = true ]; then
    _EXTRA_PATH="$HOME/Library/Python/3.9/bin:$_EXTRA_PATH"
fi
export PATH="$_EXTRA_PATH:$PATH"

# Update symlink for all tmux tabs
if [ -S "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/ssh_auth_sock" ]; then
    ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock
fi
export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"

# Auto attach to tmux session
# Should come before instant prompt
if [ -t 0 ] && [ -z "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
    if tmux has-session -t auto >/dev/null 2>&1; then
        exec tmux -2 attach -t auto
    else
        exec tmux -2 new-session -s auto
    fi
fi

# Should come before instant prompt
export CURRENT_TTY=$(tty)
export GPG_TTY="$CURRENT_TTY"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Download plugin manager if we don't have it
if ! [[ -e $ZDOTDIR/antidote ]]
then
    git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/antidote
fi

# Make plugin folder names pretty
zstyle ':antidote:bundle' use-friendly-names 'yes'

# Source and load plugins found in ${ZDOTDIR}/.zsh_plugins.txt
source $ZDOTDIR/antidote/antidote.zsh

# Set oh-my-zsh variables
ZSH=$(antidote path ohmyzsh/ohmyzsh)
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
[[ -d "$ZSH_CACHE_DIR/completions" ]] || mkdir -p "$ZSH_CACHE_DIR/completions"

# Enable custom completion
fpath=("$ZSH_CACHE_DIR/completions" $fpath)
fpath=("$HOME/.zsh_completion" $fpath)
if [ "$MACOS" = true ]; then
    _BUCK_COMPLETION_MODES="mac opt-mac macpy"
else
    _BUCK_COMPLETION_MODES="dev opt"
fi

# Load Antidote
antidote load

# Aliases
alias dof="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
alias hgsl="hg sl"
alias less="cless"
alias ls="lsd"
alias lt="ls --tree"
alias mosh="mosh -6"
alias please='sudo $(fc -ln -1)'
alias runp="lsof -i"
alias sl="subl"
alias sudo="sudo " # hack to make these aliases available for sudo
alias usage="du -h -d1 | sort -h"
alias vim="nvim"

# fasd shortcuts to print best match
function f1() {
    fasd -lf $1 | tail -n1
}

function d1() {
    fasd -ld $1 | tail -n1
}

if [ "$MACOS" = true ]; then
    # Open man page as PDF
    function manpdf() {
        man -t "${1}" | open -f -a /System/Applications/Preview.app/
    }

    # Change working directory to the top-most Finder window location
    function cdf() { # short for `cdfinder`
        cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')";
    }
fi

# ZSH_AUTOSUGGEST_USE_ASYNC="true" # causes errors

# Configure colorize plugin
ZSH_COLORIZE_TOOL=chroma

# History size
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
POWERLEVEL9K_MODE='nerdfont-complete'
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Facebook hg prompt
WANT_OLD_SCM_PROMPT="true"
local fb_prompt_file=/opt/facebook/share/scm-prompt
if [ -f "$fb_prompt_file" ]; then
    source "$fb_prompt_file"
fi

# Setup The Fuck
eval $(thefuck --alias)

# Turn off autocomplete beeps
unsetopt LIST_BEEP

# Write to the history file immediately, not when the shell exits.
setopt INC_APPEND_HISTORY

# Setup Rust tools
source $HOME/.cargo/env

# Configure fzf to use fd
export FZF_DEFAULT_COMMAND="fd --type file --color=always --hidden --exclude .git --exclude .hg --exclude node_modules"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--ansi --height=40% --layout=reverse --preview-window 'right:60%' --preview 'if [ -d {} ]; then lsd --tree --depth=1 --color=always --icon=always {}; else head -n 100 {} | chroma --style=emacs --filename={}; fi'"
_fzf_compgen_path() {
    fd --hidden --follow --color=always --exclude ".git" --exclude ".hg" --exclude "node_modules" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
    fd --type d --hidden --follow --color=always --exclude ".git" --exclude ".hg" --exclude "node_modules" . "$1"
}

_fzf_compgen_unalias() {
    tmpfile=$(mktemp /tmp/zsh-complete.XXXXXX)
    alias > "$tmpfile"
    fzf "$@" --preview 'ESCAPED=$(printf "%s=" {} | sed -e '"'"'s/[]\/$*.^[]/\\&/g'"'"'); cat '"$tmpfile"' | grep "^$ESCAPED"'
    rm "$tmpfile"
}

_fzf_comprun() {
    local command=$1
    shift

    case "$command" in
        export|unset) fzf "$@" --preview "eval 'echo \$'{}" ;;
        ssh|telnet)   fzf "$@" --preview 'echo {}' ;;
        unalias)      _fzf_compgen_unalias "$@" ;;
        *)            fzf "$@" ;;
    esac
}

# Enhacd configuration
ENHANCD_FILTER=fzf

case $(type "...") in
    (*alias*) unalias "...";;
esac

ENHANCD_DOT_ARG="..." # Old version
ENHANCD_ARG_DOUBLE_DOT="..." # New version
ENHANCD_DISABLE_HOME=1 # Old version
ENHANCD_ENABLE_HOME=false # New version

# you-should-use
YSU_MESSAGE_POSITION="after"
YSU_IGNORED_ALIASES=("hgsl")
COLOUR_NONE="$(tput sgr0)"
COLOUR_BOLD="$(tput bold)"
COLOUR_YELLOW="$(tput setaf 3)"
COLOUR_PURPLE="$(tput setaf 5)"
YSU_MESSAGE_FORMAT="${COLOUR_BOLD}${COLOUR_YELLOW}\
Found existing %alias_type for ${COLOUR_PURPLE}\"%command\"${COLOUR_YELLOW}. \
You can use ${COLOUR_PURPLE}\"%alias\"${COLOUR_YELLOW} instead.${COLOUR_NONE}"

# Configure Ctrl+W word deletion style
my-backward-delete-word() {
    local WORDCHARS='.-'
    zle backward-delete-word
}
zle -N my-backward-delete-word
bindkey '^W' my-backward-delete-word

# Bash style Ctrl+U
bindkey \^U backward-kill-line

# Smart case completion. Case sensitive if upper case letters are used.
# Second rule enables completion at ".", "_" and "-". Example: f.b -> foo.bar
# Third rule enables completion on the left. Example: bar -> foobar
zstyle ':completion:*' matcher-list 'm:{[:lower:]-_}={[:upper:]_-}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Enable Iterm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Enable broot
source ${HOME}/.config/broot/launcher/bash/br

# Enable fasd
eval "$(fasd --init auto)"

# pipx completions
eval "$(register-python-argcomplete pipx)"

# added by setup_fb4a.sh
if [ "$MACOS" = true ]; then
    export ANDROID_SDK=/opt/android_sdk
    export ANDROID_NDK_REPOSITORY=/opt/android_ndk
    export ANDROID_HOME=${ANDROID_SDK}
    export PATH=${PATH}:${ANDROID_SDK}/emulator:${ANDROID_SDK}/tools:${ANDROID_SDK}/tools/bin:${ANDROID_SDK}/platform-tools
fi

# This speeds up pasting w/ autosuggest
# https://github.com/zsh-users/zsh-autosuggestions/issues/238
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# Disable hashing for list of executables
zstyle ":completion:*:commands" rehash 1

# Fixed slow git autocompletion.
__git_files () {
    _wanted files expl 'local files' _files
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Load local zshrc if exists
local_zshrc="${ZDOTDIR}/.zshrc.local"
if [[ -f $local_zshrc ]]; then
    source $local_zshrc
fi

# Make sure there are no errors on shell load.
true
