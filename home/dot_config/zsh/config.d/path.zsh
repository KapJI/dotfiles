# Set PATH

_EXTRA_PATH=(
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/.npm/bin"
    "$HOME/.iterm2"
    "$HOME/.cargo/bin"
    "$HOME/.yarn/bin"
    "$HOME/.config/yarn/global/node_modules/.bin"
)

if [ "$MACOS" = true ]; then
    _EXTRA_PATH+=("/opt/homebrew/bin")
fi

_EXTRA_PATH+=("/usr/local/bin")

export PATH="$(printf ":%s" "${_EXTRA_PATH[@]}"):$PATH"
