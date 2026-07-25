# This speeds up pasting w/ autosuggest
# https://github.com/zsh-users/zsh-autosuggestions/issues/238
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# Add 'bracketed-paste' but it's not possible to append.
# https://github.com/zsh-users/zsh-autosuggestions/issues/351
ZSH_AUTOSUGGEST_CLEAR_WIDGETS=(
  history-search-forward
  history-search-backward
  history-beginning-search-forward
  history-beginning-search-backward
  history-beginning-search-forward-end
  history-beginning-search-backward-end
  history-substring-search-up
  history-substring-search-down
  up-line-or-beginning-search
  down-line-or-beginning-search
  up-line-or-history
  down-line-or-history
  accept-line
  copy-earlier-word
  bracketed-paste
)

# Async is already ON, and not because of any line here: the plugin sets
# ZSH_AUTOSUGGEST_USE_ASYNC (empty but present) on zsh >= 5.0.8 and keys off
# the parameter being *set*, not its value — so a commented-out assignment
# never mattered. The old "causes errors" was the pre-5.0.8 ^C bug (upstream
# issue #364), now irrelevant on our zsh. To actually disable async you would
# `unset ZSH_AUTOSUGGEST_USE_ASYNC` after the plugin loads.

# Bind autosuggest's widget wrappers ONCE at the first precmd instead of
# on every precmd (upstream's default exists to stay outermost if other
# plugins rewrap widgets at runtime — nothing here does; fsh/fzf-tab all
# wire up during zshrc, before the first prompt). Measured cost of the
# default re-bind: ~9ms per prompt.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
