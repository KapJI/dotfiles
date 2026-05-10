# Treat `/` and shell metachars as word boundaries everywhere (Ctrl-W,
# Alt-B/F, Alt-D, Alt-Backspace). Default WORDCHARS includes `/`, so
# Ctrl-W on `rm /a/b/c` wipes the whole path in one shot. Keeping just
# `_`, `-`, `.` in-word matches editor conventions: `snake_case` and
# `kebab-case` stay as one word, but `path/to/file` splits cleanly.
WORDCHARS='_-.'

# Bash style Ctrl+U
bindkey \^U backward-kill-line
