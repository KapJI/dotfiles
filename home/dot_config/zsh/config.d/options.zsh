# Turn off all beeps
setopt NO_BEEP

# Allow tab completion in the middle of a word
setopt COMPLETE_IN_WORD

# Match files beginning with a dot without explicitly specifying the dot
setopt GLOBDOTS

# History options. Some of these are also set by OMZ's lib/history.zsh, but
# being explicit here decouples behavior from upstream changes and keeps
# every history-related decision visible in one place.
setopt EXTENDED_HISTORY        # record timestamp:elapsed:command in HISTFILE
setopt SHARE_HISTORY           # share between parallel sessions; implies INC_APPEND_HISTORY
setopt HIST_VERIFY             # `!!` and friends require Enter again before executing
setopt HIST_IGNORE_ALL_DUPS    # drop older duplicate of any new command being added
setopt HIST_SAVE_NO_DUPS       # never write a duplicate event to the history file
setopt HIST_FIND_NO_DUPS       # when searching history, skip already-shown matches
setopt HIST_IGNORE_SPACE       # leading-space command → not recorded (one-off secrets)
setopt HIST_REDUCE_BLANKS      # collapse runs of whitespace before saving
setopt HIST_EXPIRE_DUPS_FIRST  # when HISTFILE is at capacity, evict dups before uniques
