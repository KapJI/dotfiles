## Tell the outer terminal (wezterm) whether we're inside tmux.
##
## WezTerm's split-navigation forwarding (M-hjkl) checks the IS_TMUX
## user-var on the pane. When set to "true", it forwards Alt-keys to the
## inner app (tmux/nvim); when "false" or unset, it handles the keys itself
## for wezterm pane nav.
##
## Why on `precmd`:
##   - Tmux's client-attached hook can emit IS_TMUX=true on attach, but
##     client-detached can't (the client tty is gone by then), leaving the
##     var stale and trapping Alt-keys after detach.
##   - Emitting from the shell prompt is self-healing: when you detach and
##     fall back to the bare ssh / local shell, $TMUX is unset, the next
##     prompt emits IS_TMUX=false, and wezterm starts handling Alt-keys
##     locally again.
##   - Cost: one printf per prompt redraw. Negligible.
##
## OSC 1337 SetUserVar with base64-encoded value (per iTerm2 / WezTerm spec):
##   echo -n true  | base64  →  dHJ1ZQ==
##   echo -n false | base64  →  ZmFsc2U=
_wezterm_emit_is_tmux() {
    if [[ -n "$TMUX" ]]; then
        printf '\033]1337;SetUserVar=IS_TMUX=dHJ1ZQ==\007'
    else
        printf '\033]1337;SetUserVar=IS_TMUX=ZmFsc2U=\007'
    fi
}

# Fire once at shell startup (covers fresh shells), then on every prompt.
_wezterm_emit_is_tmux
typeset -ag precmd_functions
precmd_functions+=(_wezterm_emit_is_tmux)
