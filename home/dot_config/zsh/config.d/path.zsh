# Set PATH

# Keep first occurrence of each entry
typeset -U path

local -a extra=(
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/.npm/bin"
    "$HOME/.iterm2"
    "$HOME/.cargo/bin"
    "$HOME/.yarn/bin"
    "$HOME/.config/yarn/global/node_modules/.bin"
)

if [ "$MACOS" = true ]; then
    extra+="/opt/homebrew/bin"
fi

extra+="/usr/local/bin"

path=( $extra $path )

export PATH
