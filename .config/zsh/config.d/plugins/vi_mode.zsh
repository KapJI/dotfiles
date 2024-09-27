# Initialise fzf here for compatibility with vi mode
function zvm_after_init() {
  eval "$(fzf --zsh)"
  source "$(antidote path ohmyzsh/ohmyzsh)/plugins/zsh-interactive-cd/zsh-interactive-cd.plugin.zsh"
}
