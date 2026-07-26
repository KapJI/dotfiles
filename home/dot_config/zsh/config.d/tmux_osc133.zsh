# Advertise OSC 133 prompt-mark capability to tmux, per pane.
#
# tmux's Alt-Y "copy last command output" binding (dot_tmux.conf.tmpl)
# navigates by the OSC 133 prompt marks that the iterm2 shell-integration
# plugin emits (133;A prompt start, 133;C output start). tmux records those
# marks and previous-prompt/next-prompt jump between them — but nothing in a
# capture-pane snapshot proves the marks exist. A bare shell whose PS1 merely
# contains a ❯ glyph looks identical on screen yet has no marks, and there
# previous-prompt/next-prompt are silent no-ops, so a glyph-counting guard
# would make Alt-Y slice garbage.
#
# So the shell that actually has the integration tells tmux directly: it sets
# a per-pane user option keyed on $TMUX_PANE (the pane this shell runs in).
# The binding gates on #{@osc133_capable}; a shell that never advertised it
# (a bare `zsh -f`, a login shell without the plugin) leaves it unset, and
# Alt-Y cleanly reports "nothing to copy" instead of copying garbage.
#
# Re-assert on every prompt (idempotent), not once: the retract hook below
# clears the flag whenever an integrated shell exits, so a *parent* integrated
# shell — one that spawned a nested integrated zsh which has since exited and
# retracted — must be able to set it again on its next prompt. One tmux
# invocation per prompt is negligible for an interactive shell.
# ITERM_SHELL_INTEGRATION_INSTALLED is set (to "Yes") by the integration plugin
# only when it actually armed itself for this interactive shell.
if [[ -n ${TMUX:-} ]]; then
  autoload -Uz add-zsh-hook

  _osc133_advertise_to_tmux() {
    if [[ -n ${ITERM_SHELL_INTEGRATION_INSTALLED:-} && -n ${TMUX_PANE:-} ]]; then
      command tmux set -p -t "$TMUX_PANE" @osc133_capable 1 2>/dev/null
    fi
  }
  add-zsh-hook precmd _osc133_advertise_to_tmux

  # Retract the capability when this shell exits, so a pane handed back to a
  # non-integrated shell (an integrated zsh exiting to a plain login bash)
  # doesn't leave Alt-Y trusting OSC 133 marks whose emitter is gone. This
  # covers the nested-shell-exit path. It does NOT cover ssh'ing from here into
  # a host without the integration: this zsh stays alive, so zshexit never
  # fires and no prompt redraws to re-assert — the flag lingers at 1 for that
  # remote session, a narrow edge the binding degraded on before this flag
  # existed and no worse now. Unsetting an already-unset option, or one on a
  # pane that vanished as the shell exited, is a harmless no-op.
  _osc133_retract_from_tmux() {
    [[ -n ${TMUX_PANE:-} ]] && command tmux set -up -t "$TMUX_PANE" @osc133_capable 2>/dev/null
  }
  add-zsh-hook zshexit _osc133_retract_from_tmux
fi
