# Enable zoxide. Cached to avoid forking zoxide (~5ms) on every startup;
# _zsh_cache_eval regenerates the cache whenever the zoxide binary changes
# (see init_tools.zsh).
_zsh_cache_eval zoxide-init.zsh zoxide zoxide init zsh
export _ZO_FZF_OPTS="--no-sort \
--bind=ctrl-z:ignore,btab:up,tab:down \
--cycle \
--keep-right \
--border=sharp \
--height=50% \
--layout=reverse \
--tabstop=1 \
--exit-0 \
--preview='eza --group-directories-first --color=always --icons=always {2..}' \
--preview-window=down,30%,sharp"
