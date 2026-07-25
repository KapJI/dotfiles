# Clean-env reload. Plain `exec zsh` inherits FPATH/MANPATH/etc from the
# parent process; on NixOS those still point at the previous generation
# even after `nix-rebuild`, so antidote re-sources stale plugin files
# (fzf-tab loaded from a now-gc'd store path was the trigger). `env -i`
# strips everything and lets /etc/zshenv + ~/.zshenv repopulate from the
# current generation. Cost on top of `exec zsh` is sub-100ms; benefit is
# one reload command that behaves identically on macOS/Debian/NixOS.
reload() {
    local -a preserve=(
        HOME USER SHELL TERM LANG LC_ALL
        XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_RUNTIME_DIR
        COLORTERM TERM_PROGRAM TERM_PROGRAM_VERSION
        SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT SSH_TTY
        TMUX TMUX_PANE
        DISPLAY WAYLAND_DISPLAY
        # Session-identity vars that rc files don't repopulate: the
        # session bus (GUI/notify tools), and wezterm's control socket +
        # pane id (so `wezterm cli` keeps working after a reload).
        DBUS_SESSION_BUS_ADDRESS
        WEZTERM_UNIX_SOCKET WEZTERM_PANE
    )
    local -a env_args=() v
    for v in $preserve; do
        [[ -n ${(P)v} ]] && env_args+=("$v=${(P)v}")
    done
    # Exec $SHELL by absolute path, not bare `zsh`: with PATH stripped,
    # `env` would resolve `zsh` against its built-in default path
    # (/usr/bin:/bin), which on NixOS holds no zsh. $SHELL is preserved
    # above and is already absolute.
    exec env -i "${env_args[@]}" "$SHELL" -l
}

# Aliases
alias fd="fd --hidden"
alias rg="rg --hidden"
alias ls="eza --icons=always --group --all"
alias lt="eza --icons=always --tree --all"
alias l="eza --icons=always -l --group --all"
alias mosh="mosh -6"
alias runp="lsof -i"
alias sl="subl"
alias sudo="sudo " # hack to make these aliases available for sudo
alias usage="du -h -d1 | sort -h"
alias vim="nvim"
alias czm="chezmoi"
# Single quotes: defer `chezmoi source-path` to use time instead of
# spawning chezmoi on every shell startup.
alias czmcd='cd "$(chezmoi source-path)"'
# Bump every pinned dependency lock in one shot, then re-add the changed files
# to the chezmoi source — the merge of the old nix-bump-lock and
# zsh-bump-plugins. Two locks:
#   1. the nix flake (flake.lock) — nixpkgs + claude-code-nix.
#   2. the antidote plugin pins (.zsh_plugins.txt) — each pin:<sha> rewritten
#      to its repo's upstream default-branch HEAD. One lookup per repo (cached)
#      so ohmyzsh's several lines stay in lockstep on one commit; a failed
#      lookup leaves that pin untouched.
# (antidote itself is pinned in .chezmoiexternal.toml, a chezmoi-config file
# with no re-add target — bump it there by hand.) After running, review/commit:
#   chezmoi cd && git diff
# The new plugin SHAs are checked out at the next shell (antidote regenerates
# its static bundle and syncs pins), or on other hosts at the next apply.
bump-locks() {
    emulate -L zsh
    setopt local_options extended_glob
    print "==> nix flake update"
    nix flake update --flake ~/.config/nix-profile || return 1
    print "==> antidote plugin pins -> upstream HEAD"
    local f=$ZDOTDIR/.zsh_plugins.txt
    if [[ -r $f ]]; then
        local line repo
        local -A cache
        local -a out
        while IFS= read -r line || [[ -n $line ]]; do
            if [[ $line != '#'* && $line == *pin:* ]]; then
                repo=${line%%[[:space:]]*}
                if [[ -z ${cache[$repo]:-} ]]; then
                    cache[$repo]=$(git ls-remote "https://github.com/$repo" HEAD 2>/dev/null | awk 'NR==1{print $1}')
                fi
                [[ -n ${cache[$repo]:-} ]] && line=${line/pin:[[:xdigit:]]##/pin:${cache[$repo]}}
            fi
            out+=$line
        done < $f
        print -rl -- "${out[@]}" > $f
    else
        print -u2 "bump-locks: skipping plugins ($f not readable)"
    fi
    print "==> chezmoi re-add"
    chezmoi re-add ~/.config/nix-profile/flake.lock $f
    print "bump-locks: flake.lock + plugin pins updated and re-added to chezmoi."
    print "Review/commit: chezmoi cd && git diff"
}

# yazi wrapper: cd shell to whatever directory yazi was in when you quit.
# Without this, quitting yazi leaves you in the dir you started from,
# defeating the point of using it as a navigator. Canonical wrapper from
# yazi-rs.github.io/docs/quick-start#shell-wrapper. Named yz to avoid
# colliding with vim-yank muscle memory; type yz to launch.
function yz() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(< "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# Git aliases from oh-my-zsh
alias g="git"
alias ga="git add"
alias gb="git branch"
alias gc="git commit"
alias gco="git checkout"
alias gcl="git clone"
alias gcam="git commit --all --message"
alias gcm="git commit --message"
alias gcn!="git commit --verbose --no-edit --amend"
alias gcan!="git commit --verbose --all --no-edit --amend"
alias gd="git diff"
alias gds="git diff --staged"
alias gf="git fetch"
alias gmv="git mv"
alias gpl="git pull"
alias gplra="git pull --rebase --autostash"
alias gp="git push"
# Safe force-push default: --force-with-lease refuses to clobber remote
# commits you haven't fetched; --force-if-includes additionally requires
# your local ref to include the remote tip. gpf! stays as the raw,
# no-questions-asked escape hatch.
alias gpf="git push --force-with-lease --force-if-includes"
alias gpf!="git push --force"
alias gr="git remote"
alias grb="git rebase"
alias grs="git restore"
alias grm="git rm"
alias gsh="git show"
alias gst="git status"
alias gsl="git sl"

if command -v nala &> /dev/null; then
    alias apt="nala"
fi

# https://github.com/sharkdp/bat
alias bathelp='bat --plain --language=help'
help() {
    "$@" --help 2>&1 | bathelp
}

rgd() {
    command rg --hidden --json -C 2 "$@" | delta
}
