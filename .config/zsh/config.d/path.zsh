# Set PATH

_ORIGINAL_PATH="$PATH"

# Required to find go for GOPATH
if [ "$MACOS" = true ]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi
# Required for chroma (which is used by colorize plugin).
export GOPATH=$(go env GOPATH)

_EXTRA_PATH=(
    "$HOME/bin"
    "$HOME/.local/bin"
    "$GOPATH/bin"
    "/usr/local/bin"
    "$HOME/.npm/bin"
    "$HOME/.iterm2"
    "$HOME/.yarn/bin"
    "$HOME/.config/yarn/global/node_modules/.bin"
)

if [ "$MACOS" = true ]; then
    _EXTRA_PATH+=("/opt/homebrew/bin")
fi
export PATH="$(printf ":%s" "${_EXTRA_PATH[@]}"):${_ORIGINAL_PATH}"
