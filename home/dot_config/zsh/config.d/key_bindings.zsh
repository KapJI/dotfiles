# Configure Ctrl+W word deletion style
my-backward-delete-word() {
    local WORDCHARS='.-'
    zle backward-delete-word
}
zle -N my-backward-delete-word
bindkey '^W' my-backward-delete-word

# Bash style Ctrl+U
bindkey \^U backward-kill-line
