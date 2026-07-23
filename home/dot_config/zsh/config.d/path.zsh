# Set PATH

# Keep first occurrence of each entry
typeset -U path

# Anonymous function so `extra` stays local — at file scope `local` is
# just `typeset` and would leak a global into every shell.
() {
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
}

export PATH
