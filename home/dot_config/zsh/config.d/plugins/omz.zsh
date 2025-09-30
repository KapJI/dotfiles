# Hack to disable cwd reporting in oh-my-zsh/lib/termsupport.zsh
add-zsh-hook -d precmd omz_termsupport_cwd

# Replace with my own implementation using shrink_path
add-zsh-hook -d precmd omz_termsupport_precmd
