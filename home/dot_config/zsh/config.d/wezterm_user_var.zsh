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
##
## Inside tmux, the OSC must be wrapped in tmux's DCS passthrough
## (\ePtmux;…\e\\) so tmux forwards it to the outer terminal instead
## of stripping it. Modern tmux removes unknown OSCs from pane output
## even with `allow-passthrough on`; the DCS wrap is the explicit
## "pass this through unchanged" mechanism. Outside tmux, emit the
## bare OSC directly to the terminal.
_wezterm_emit_is_tmux() {
    # Only when stdout is a terminal. Without this, an interactive shell whose
    # stdout is captured — e.g. out=$(zsh -ic '…') — emits this OSC into the
    # captured text, corrupting it. The terminal is the only consumer anyway.
    [[ -t 1 ]] || return
    # Skip terminals that don't speak OSC 1337: the Linux VC and dumb parse
    # unknown OSC poorly (garbage/bells on some), and neither is wezterm. Same
    # guard the vendored iterm2 integration already applies
    # (plugins/iterm2_shell_integration.zsh). Every other TERM still emits —
    # the detach self-heal depends on plain-ssh shells (TERM=xterm-*)
    # advertising IS_TMUX=false, and well-behaved terminals ignore unknown OSC.
    [[ $TERM == (linux|dumb) ]] && return
    if [[ -n "$TMUX" ]]; then
        printf '\033Ptmux;\033\033]1337;SetUserVar=IS_TMUX=dHJ1ZQ==\007\033\\'
    else
        printf '\033]1337;SetUserVar=IS_TMUX=ZmFsc2U=\007'
    fi
}

# Fire once at shell startup (covers fresh shells), then on every prompt.
_wezterm_emit_is_tmux
add-zsh-hook precmd _wezterm_emit_is_tmux
