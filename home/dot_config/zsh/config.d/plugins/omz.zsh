# Hack to disable cwd reporting in oh-my-zsh/lib/termsupport.zsh
add-zsh-hook -d precmd omz_termsupport_cwd

# Replaced by the title logic in config.d/auto_title.zsh
add-zsh-hook -d precmd omz_termsupport_precmd

# Same reason for the preexec twin: auto_title.zsh's _atit_preexec_glyph
# runs after this and overwrites the title on every command, so OMZ's
# preexec title-setter only emits a redundant OSC beforehand. Drop it.
add-zsh-hook -d preexec omz_termsupport_preexec
