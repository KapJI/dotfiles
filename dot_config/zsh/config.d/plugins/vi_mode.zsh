# Initialise fzf here for compatibility with vi mode
function zvm_after_init() {
  eval "$(fzf --zsh)"
  zvm_bindkey viins "^Z" fancy-ctrl-z
}
