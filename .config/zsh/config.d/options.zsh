# Turn off all beeps
setopt NO_BEEP


# Allow tab completion in the middle of a word
setopt COMPLETE_IN_WORD

# Share history between parallel sessions
setopt SHARE_HISTORY

# If a new command line being added to the history list duplicates an older one, 
# the older command is removed from the list (even if it is not the previous event).
setopt HIST_IGNORE_ALL_DUPS

# Execute command with history expansion immediately (e.g. !*)
setopt NO_HIST_VERIFY

# When writing out the history file, older commands that duplicate newer ones are omitted
setopt HIST_SAVE_NO_DUPS

# Match files beginning with a dot without explicitly specifying the dot
setopt GLOBDOTS
