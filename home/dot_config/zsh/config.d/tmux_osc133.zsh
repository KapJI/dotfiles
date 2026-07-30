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
# Re-assert on every prompt (idempotent), not once: the retract hooks below
# clear the flag whenever a foreground command starts or an integrated shell
# exits, so each next prompt — of this shell, or of a *parent* integrated
# shell whose nested integrated zsh has since exited and retracted — must set
# it again. One tmux invocation per prompt is negligible for an interactive
# shell.
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

  # Retract the capability whenever this shell stops controlling the pane, so
  # Alt-Y never trusts OSC 133 marks whose emitter is gone:
  #
  #   - preexec: from here until the next precmd, a foreground command owns
  #     the pane — and it may hand it to a shell with no integration (ssh to
  #     a host without it, docker exec, a plain nested bash). If the flag
  #     stayed set, Alt-Y during that session would navigate this shell's old
  #     local prompt marks and copy a stale span — potentially a large chunk
  #     of remote output — to the clipboard. Retracting first makes Alt-Y
  #     degrade to "nothing to copy" for the whole foreground session; the
  #     next local prompt re-asserts. That also disables Alt-Y *during* quick
  #     local commands — a deliberate fail-safe trade, and it costs one tmux
  #     call per command, same order as the precmd advertise.
  #   - zshexit: the pane is handed back to whatever spawned this shell (an
  #     integrated zsh exiting to a plain login bash). Needed besides preexec
  #     because an exit that never runs a command (^D at the prompt) fires no
  #     preexec, and the parent re-assert path in the header relies on it.
  #
  # Unsetting an already-unset option, or one on a pane that vanished as the
  # shell exited, is a harmless no-op.
  _osc133_retract_from_tmux() {
    [[ -n ${TMUX_PANE:-} ]] && command tmux set -up -t "$TMUX_PANE" @osc133_capable 2>/dev/null
  }
  add-zsh-hook preexec _osc133_retract_from_tmux
  add-zsh-hook zshexit _osc133_retract_from_tmux
fi
