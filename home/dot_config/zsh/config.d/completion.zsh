# Enable custom completions
fpath=("$ZDOTDIR/custom_completion" $fpath)

# Enable Nix-shipped completions (user profile + system default profile).
# Covers any tool installed via nix: keys in packages.yaml.
[ -d "$HOME/.nix-profile/share/zsh/site-functions" ] && \
    fpath+=("$HOME/.nix-profile/share/zsh/site-functions")
[ -d /nix/var/nix/profiles/default/share/zsh/site-functions ] && \
    fpath+=(/nix/var/nix/profiles/default/share/zsh/site-functions)

# Enable Homebrew completions
if [ "$MACOS" = true ]; then
    fpath+=("$(brew --prefix)/share/zsh/site-functions")
fi

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

# Hide "." and ".." for completion list. Show ".." only when it's explicitly given.
zstyle -e ':completion:*' special-dirs '[[ ${PREFIX##*/} == ".." ]] && reply=(..)'

# Preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'

# Preview files (bat) and directories (eza) when completing common
# file-opening commands. $realpath is fzf-tab's resolved absolute path
# for the candidate; falls back to a directory listing for dirs.
zstyle ':fzf-tab:complete:(nvim|vim|nano|cat|bat|less|head|tail|cp|mv|rm|chmod|chown|wc|file|stat|du):*' \
    fzf-preview '
        if [[ -d $realpath ]]; then
            eza -1 --color=always --icons=always $realpath
        else
            bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null
        fi
    '

# Switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# Remove prefix from every option
zstyle ':fzf-tab:*' prefix ''

# Fixed slow git autocompletion.
__git_files () {
    _wanted files expl 'local files' _files
}
