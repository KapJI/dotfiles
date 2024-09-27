# Hack to disable cwd reporting in oh-my-zsh/lib/termsupport.zsh
add-zsh-hook -d precmd omz_termsupport_cwd
