# Treat `/` and shell metachars as word boundaries everywhere (Ctrl-W,
# Alt-B/F, Alt-D, Alt-Backspace). Default WORDCHARS includes `/`, so
# Ctrl-W on `rm /a/b/c` wipes the whole path in one shot. Keeping just
# `_`, `-`, `.` in-word matches editor conventions: `snake_case` and
# `kebab-case` stay as one word, but `path/to/file` splits cleanly.
WORDCHARS='_-.'

# Bash style Ctrl+U
bindkey \^U backward-kill-line

# Alt+e — edit the current command line in $EDITOR. A faster single
# chord for the `edit-command-line` widget; the readline-standard
# `^X^E` (autoloaded by OMZ's lib) still works too. Alt+e is unbound
# in zsh's default emacs keymap, so no collision.
bindkey '^[e' edit-command-line
