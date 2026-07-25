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
# Set once, at the first prompt — the hook removes itself — so it costs a
# single tmux invocation per shell, not one per command. ITERM_SHELL_-
# INTEGRATION_INSTALLED is set (to "Yes") by the integration plugin only when
# it actually armed itself for this interactive shell.
if [[ -n ${TMUX:-} ]]; then
  autoload -Uz add-zsh-hook

  _osc133_advertise_to_tmux() {
    if [[ -n ${ITERM_SHELL_INTEGRATION_INSTALLED:-} && -n ${TMUX_PANE:-} ]]; then
      command tmux set -p -t "$TMUX_PANE" @osc133_capable 1 2>/dev/null
    fi
    add-zsh-hook -d precmd _osc133_advertise_to_tmux
    unfunction _osc133_advertise_to_tmux 2>/dev/null
  }

  add-zsh-hook precmd _osc133_advertise_to_tmux
fi
