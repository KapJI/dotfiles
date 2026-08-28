# Detect whether this interactive shell was launched to run a command
# string (`zsh -ic '…'`), e.g. a VS Code task — in which case we must not
# hijack it with tmux. zsh, unlike bash, does NOT put `c` in $- for -c, so
# the old `[[ $- == *c* ]]` test never fired; ZSH_EXECUTION_STRING holds the
# command for -c/-ic and is unset for a plain interactive shell.
if [[ -n ${ZSH_EXECUTION_STRING:-} ]]; then
  VSCODE_TASK=true
else
  VSCODE_TASK=false
fi

# HERDR_ENV: herdr is itself the multiplexer, so a pane must not hijack into
# tmux. Under `herdr --remote` the panes are plain login shells with no $TMUX,
# so without this every one of them attaches to the same `main` session.
if [[ ${VSCODE_TASK:-} == false ]] && [ -t 0 ] && [ -z "$TMUX" ] && [ -z "${HERDR_ENV:-}" ] && command -v tmux >/dev/null 2>&1; then
    # `&& exit` keeps the original UX (detach = logout) but lets us fall
    # through to plain zsh if tmux can't start — `exec`'s replace-shell
    # behaviour would leave the host unloginnable in that case.
    tmux new -A -s main && exit
fi
