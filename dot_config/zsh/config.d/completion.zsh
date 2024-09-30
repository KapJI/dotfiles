# Enable custom completion
fpath=("$ZDOTDIR/custom_completion" $fpath)

# Smart case completion. Case sensitive if upper case letters are used.
# Second rule enables completion at ".", "_" and "-". Example: f.b -> foo.bar
# Third rule enables completion on the left. Example: bar -> foobar
zstyle ':completion:*' matcher-list 'm:{[:lower:]-_}={[:upper:]_-}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Disable hashing for list of executables
zstyle ':completion:*:commands' rehash 1

# Disable sorting when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# Set descriptions format without escape sequences (like '%F{red}%d%f')
zstyle ':completion:*' format '[%d]'
zstyle ':completion:*:corrections' format '[%d (errors: %e)]'

# Remove -- separator between columns
zstyle ':completion:*' list-separator ''

# Set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no

# Preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:__enhancd::cd:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'

# Switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# Remove prefix from every option
zstyle ':fzf-tab:*' prefix ''

# Fixed slow git autocompletion.
__git_files () {
    _wanted files expl 'local files' _files
}
