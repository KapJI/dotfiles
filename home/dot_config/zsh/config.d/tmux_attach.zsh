# Detect if we are inside vscode task:
if [[ $- == *c* ]]; then
  VSCODE_TASK=true
else
  VSCODE_TASK=false
fi

if [[ ${VSCODE_TASK:-} == false ]] && [ -t 0 ] && [ -z "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
    # `&& exit` keeps the original UX (detach = logout) but lets us fall
    # through to plain zsh if tmux can't start — `exec`'s replace-shell
    # behaviour would leave the host unloginnable in that case.
    tmux new -A -s auto && exit
fi
