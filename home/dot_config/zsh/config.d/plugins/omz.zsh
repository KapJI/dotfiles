# Hack to disable cwd reporting in oh-my-zsh/lib/termsupport.zsh
add-zsh-hook -d precmd omz_termsupport_cwd

# Replaced by the title logic in config.d/auto_title.zsh
add-zsh-hook -d precmd omz_termsupport_precmd
