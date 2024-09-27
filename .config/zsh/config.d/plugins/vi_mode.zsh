# Initialise fzf here for compatibility with vi mode
function zvm_after_init() {
  eval "$(fzf --zsh)"
}
