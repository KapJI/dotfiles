# Turn off all beeps
unsetopt BEEP

# Write to the history file immediately, not when the shell exits.
setopt INC_APPEND_HISTORY

# Allow tab completion in the middle of a word.
setopt COMPLETE_IN_WORD

# Enable extended history with timestamps
setopt EXTENDED_HISTORY

# Disable verification on history expanstion (e.g. !*)
setopt NO_HIST_VERIFY

# Match files beginning with a dot without explicitly specifying the dot
setopt GLOBDOTS
