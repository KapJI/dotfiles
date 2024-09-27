# Detect if we are inside vscode task:
if [[ $- == *c* ]]; then
  VSCODE_TASK=true
else
  VSCODE_TASK=false
fi

if [[ ${VSCODE_TASK:-} == false ]] && [ -t 0 ] && [ -z "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
    if tmux has-session -t auto >/dev/null 2>&1; then
        exec tmux -2 attach -t auto
    else
        exec tmux -2 new-session -s auto
    fi
fi
