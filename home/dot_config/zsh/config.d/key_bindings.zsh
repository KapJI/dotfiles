# Treat `/` and shell metachars as word boundaries everywhere (Ctrl-W,
# Alt-B/F, Alt-D, Alt-Backspace). Default WORDCHARS includes `/`, so
# Ctrl-W on `rm /a/b/c` wipes the whole path in one shot. Keeping just
# `_`, `-`, `.` in-word matches editor conventions: `snake_case` and
# `kebab-case` stay as one word, but `path/to/file` splits cleanly.
WORDCHARS='_-.'

# Bash style Ctrl+U
bindkey \^U backward-kill-line

# Alt+e — edit the current command line in $EDITOR. A faster single
# chord than the readline-standard `^X^E`; Alt+e is unbound in zsh's
# default emacs keymap, so no collision. Both keys point at the
# `_atit_edit_command_line` wrapper (defined in auto_title.zsh) rather
# than the bare `edit-command-line` widget — the wrapper re-emits the
# directory title after the editor exits (the editor sets its own
# title and no precmd fires on return).
bindkey '^[e'  _atit_edit_command_line
bindkey '^X^E' _atit_edit_command_line
