# Auto attach to tmux session
# Should come before instant prompt
if [ "$TERM" != "nuclide" ] && [ -t 0 ] && [ -z "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
    if tmux has-session -t auto >/dev/null 2>&1; then
        exec tmux -2 attach -t auto
    else
        exec tmux -2 new-session -s auto
    fi
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

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
            debian|ubuntu)
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
export GOPATH=$(go env GOPATH)
export GPG_TTY=$(tty)

_EXTRA_PATH="$GOPATH/bin:$HOME/bin:/usr/local/bin"
if [ "$MACOS" = true ]; then
    _EXTRA_PATH="$_EXTRA_PATH:/opt/homebrew/bin"
fi
export PATH="$_EXTRA_PATH:$PATH"

# Load Antigen (should come before aliases)
source ~/antigen.zsh
# Load Antigen configurations
antigen init ~/.antigenrc

# Aliases
alias mosh="mosh -6"
alias ls="lsd"
alias lt="ls --tree"
alias less="cless"
alias please='sudo $(fc -ln -1)'
alias usage="du -h -d1 | sort -h"
alias runp="lsof -i"
alias vim="nvim"
alias hgsl="hg sl"
alias dotfiles="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
alias dof="dotfiles"

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

# Enable custom completion
fpath=( ~/.zsh_completion "${fpath[@]}" )
if [ "$MACOS" = true ]; then
    _BUCK_COMPLETION_MODES="mac opt-mac macpy"
else
    _BUCK_COMPLETION_MODES="dev opt"
fi

# Enhacd configuration
ENHANCD_FILTER=fzf
unalias "..."
ENHANCD_DOT_ARG="..."
ENHANCD_DISABLE_HOME=1

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
zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}'

# Enable Iterm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Enable broot
source ${HOME}/.config/broot/launcher/bash/br

# Enable fasd
eval "$(fasd --init auto)"

# added by setup_fb4a.sh
if [ "$MACOS" = true ]; then
    export ANDROID_SDK=/opt/android_sdk
    export ANDROID_NDK_REPOSITORY=/opt/android_ndk
    export ANDROID_HOME=${ANDROID_SDK}
    export PATH=${PATH}:${ANDROID_SDK}/emulator:${ANDROID_SDK}/tools:${ANDROID_SDK}/tools/bin:${ANDROID_SDK}/platform-tools
fi