# Detect if we are inside vscode task:
if [[ $- == *c* ]]; then
  VSCODE_TASK=true
else
  VSCODE_TASK=false
fi

if [[ ${VSCODE_TASK:-} == false ]] && [ -t 0 ] && [ -z "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
    # If tmux server is unreachable but a socket file lingers (e.g.
    # crashed server, OOM kill), `tmux new -A` would fail because the
    # socket exists but can't be bound. Detect via `list-sessions`
    # failure and unlink the stale socket so the next `new -A` starts
    # a fresh server.
    if ! tmux list-sessions &>/dev/null; then
        local _tmux_sock="${TMUX_TMPDIR:-${XDG_RUNTIME_DIR:-/tmp}}/tmux-$(id -u)/default"
        [[ -S $_tmux_sock ]] && rm -f -- "$_tmux_sock"
    fi
    # `&& exit` keeps the original UX (detach = logout) but lets us fall
    # through to plain zsh if tmux can't start — `exec`'s replace-shell
    # behaviour would leave the host unloginnable in that case.
    tmux new -A -s main && exit
fi
