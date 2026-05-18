# Alt-Y — copy the previous command and its output to the clipboard.
#
# zsh keeps no scrollback of its own, so the text is read back from
# wezterm via `wezterm cli get-text` and sliced out from the last
# command's `❯` prompt line through to the current prompt — the same
# span the tmux `bind -n M-Y` binding selects on its own capture-pane.
# Inside tmux that binding intercepts Alt-Y first, so this widget only
# ever runs at a bare wezterm prompt; it no-ops (with a hint) anywhere
# it can't read a wezterm scrollback.
#
# Copies via OSC 52, so it also reaches the clipboard over SSH.

# fd of the pending confirmation-dismiss timer (armed at the end of the
# widget, cleared by _copy_last_output_dismiss).
typeset -g _copy_last_output_fd=

_copy_last_output() {
  emulate -L zsh

  if [[ -n "$TMUX" ]]; then
    zle -M "Alt-Y: inside tmux — tmux's own binding copies the last output"
    return
  fi
  if [[ $TERM_PROGRAM != WezTerm ]]; then
    zle -M "Alt-Y: not running in wezterm"
    return
  fi
  if (( ! ${+commands[wezterm]} )); then
    zle -M "Alt-Y: the wezterm CLI isn't on PATH"
    return
  fi

  # The pane to read is the focused one — Alt-Y was just pressed in it.
  # ($WEZTERM_PANE would name it directly, but wezterm doesn't export
  # that var in every setup, so ask the mux for the focused pane id.)
  local pane
  pane=$(wezterm cli list-clients --format json 2>/dev/null \
    | jq -r '.[0].focused_pane_id // empty' 2>/dev/null)
  if [[ -z $pane ]]; then
    zle -M "Alt-Y: couldn't determine the wezterm pane"
    return
  fi

  # Pane text: a generous scrollback window through the bottom of the
  # screen. Output taller than this window gets truncated at the top.
  local dump
  dump=$(wezterm cli get-text --pane-id "$pane" --start-line -2000 2>/dev/null)
  if [[ -z "$dump" ]]; then
    zle -M "Alt-Y: couldn't read the wezterm pane"
    return
  fi

  # Prompt lines are the ones carrying the `❯` glyph.
  local -a lines marks
  local i
  lines=("${(@f)dump}")
  for i in {1..$#lines}; do
    [[ ${lines[i]} == *'❯'* ]] && marks+=$i
  done
  if (( $#marks < 2 )); then
    zle -M "Alt-Y: no previous command output found"
    return
  fi

  # Capture from the last command's prompt line — the `❯ <command>`
  # line itself, matching the tmux binding — down to two lines above
  # the current prompt: our p10k prompt is two lines, so the line
  # directly above `❯` is its first segment. Trailing blanks (the
  # POWERLEVEL9K_PROMPT_ADD_NEWLINE gap, and anything the command itself
  # printed) are then trimmed.
  local start=$(( marks[-2] )) end=$(( marks[-1] - 2 ))
  local -a out
  (( end >= start )) && out=("${(@)lines[start,end]}")
  while (( $#out )) && [[ -z ${out[-1]//[[:space:]]/} ]]; do
    out[-1,-1]=()
  done
  if (( ! $#out )); then
    zle -M "Alt-Y: nothing to copy"
    return
  fi

  # OSC 52 clipboard write. base64 is piped through `tr -d` because GNU
  # coreutils base64 wraps at 76 columns — the payload must be one
  # unbroken line.
  local payload
  payload=$(print -r -- "${(F)out}" | base64 | tr -d '\n')
  printf '\033]52;c;%s\007' "$payload" > /dev/tty

  # Confirmation line: a check glyph (nf-fa-check) then plain text.
  # `zle -M` prints its argument literally — escape sequences would show
  # up verbatim (^[[32m…) — so there is no colour, just the glyph.
  local n=$#out noun=lines
  (( n == 1 )) && noun=line
  zle -M $''" Copied last command output — $n $noun"
  # `zle -M` lingers until the next keypress; arm a 3-second timer to
  # clear it if the prompt is left idle. A background `sleep` is watched
  # via `zle -F` — its EOF runs _copy_last_output_dismiss while the line
  # editor is active, where clearing the message is allowed. A still-
  # pending timer from an earlier press is cancelled first, so rapid
  # presses don't clear a newer message early.
  if [[ -n $_copy_last_output_fd ]]; then
    zle -F $_copy_last_output_fd
    exec {_copy_last_output_fd}<&-
    _copy_last_output_fd=
  fi
  exec {_copy_last_output_fd}< <(sleep 3)
  zle -F $_copy_last_output_fd _copy_last_output_dismiss
}

# zle -F handler — fires ~3s after a copy, when the `sleep` EOFs. It
# runs while the line editor is active, so it may clear the message.
# $1 is the triggering fd.
_copy_last_output_dismiss() {
  local fd=$1
  zle -F $fd
  exec {fd}<&-
  _copy_last_output_fd=
  zle -M ''
  zle -R
}

zle -N _copy_last_output
bindkey '^[Y' _copy_last_output
