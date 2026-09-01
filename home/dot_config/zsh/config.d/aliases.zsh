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
        XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_RUNTIME_DIR
        COLORTERM TERM_PROGRAM TERM_PROGRAM_VERSION
        # A terminal shipping a custom $TERM (kitty, ghostty) or a NixOS
        # profile can point $TERM's terminfo at a session/store path via
        # these; no rc file repopulates them, so env -i would strip the
        # pointer and leave $TERM (preserved above) resolving to nothing
        # — "unknown terminal type" / lost capabilities. Unset on this
        # setup (plain xterm-256color), so the loop below skips them free.
        TERMINFO TERMINFO_DIRS
        SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT SSH_TTY
        TMUX TMUX_PANE
        DISPLAY WAYLAND_DISPLAY
        # X11/XWayland credential paths: XAUTHORITY (and, rarer, ICEAUTHORITY)
        # often point at a per-session temp cookie file (GDM/Xwayland's
        # ~/.mutter-Xwaylandauth.*, or an sshd-created path under X11
        # forwarding) that no rc file recreates. Dropping it across env -i
        # leaves DISPLAY set but auth gone — X clients fail "cannot open
        # display" while the shell looks fine. Unset off-X (this host), so the
        # loop below skips them free.
        XAUTHORITY ICEAUTHORITY
        # macOS gives each login session a private TMPDIR (/var/folders/.../T)
        # set by launchd, not by any rc file — so env -i would blank it and
        # $TMPDIR consumers (mktemp, the yz wrapper above) would silently fall
        # back to the world-readable /tmp. Preserve it like the session vars
        # below; harmless on Linux where it's usually unset anyway.
        TMPDIR
        # Session-identity vars that rc files don't repopulate: the
        # session bus (GUI/notify tools), and wezterm's control socket +
        # pane id (so `wezterm cli` keeps working after a reload).
        DBUS_SESSION_BUS_ADDRESS
        WEZTERM_UNIX_SOCKET WEZTERM_PANE
        # herdr's control socket + pane identity (the wezterm pair's twin):
        # losing these kills the `herdr` CLI, every HERDR_ENV-gated config,
        # and the pane-id title suffix for the rest of the pane's life.
        HERDR_ENV HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID
        HERDR_SOCKET_PATH HERDR_BIN_PATH
    )
    local -a env_args=() v
    for v in $preserve; do
        [[ -n ${(P)v} ]] && env_args+=("$v=${(P)v}")
    done
    # Exec zsh by absolute path, not bare `zsh`: with PATH stripped, `env`
    # would resolve `zsh` against its built-in default path (/usr/bin:/bin),
    # which on NixOS holds no zsh. Resolve it here against the *current* PATH
    # (this shell's nix generation) so reload always lands on a live zsh —
    # and, unlike $SHELL, without depending on the login shell being zsh (on
    # Linux it may be bash) or on a possibly-gc'd store path. $commands
    # entries are already absolute; fall back to $SHELL if zsh isn't on PATH.
    local zsh_bin=${commands[zsh]:-$SHELL}
    exec env -i "${env_args[@]}" "$zsh_bin" -l
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
# with no re-add target — bump it there by hand.) On success it commits just
# those two source files as "deps: bump flake.lock + plugin pins"; it never
# pushes, and it commits nothing if any pin lookup failed. After running:
#   chezmoi cd && git show   # then `git push` when you are happy
# The new plugin SHAs are checked out at the next shell (antidote regenerates
# its static bundle and syncs pins), or on other hosts at the next apply.
bump-locks() {
    emulate -L zsh
    setopt local_options extended_glob
    local rc=0
    print "==> nix flake update"
    nix flake update --flake ~/.config/nix-profile || return 1
    print "==> antidote plugin pins -> upstream HEAD"
    local f=$ZDOTDIR/.zsh_plugins.txt
    if [[ -r $f ]]; then
        local line repo sha
        local -A cache
        local -a out
        while IFS= read -r line || [[ -n $line ]]; do
            if [[ $line != '#'* && $line == *pin:* ]]; then
                repo=${line%%[[:space:]]*}
                # Resolve each repo once, caching the OUTCOME — the real SHA or
                # a FAIL sentinel. Caching the failure too means a dead lookup
                # is recorded (not retried on every pin line for the same repo,
                # e.g. ohmyzsh's several lines) and warned about exactly once.
                # A failed lookup must never masquerade as success: it leaves
                # the pin untouched and trips rc so the whole command reports
                # non-zero instead of printing a cheerful "updated".
                if [[ -z ${cache[$repo]:-} ]]; then
                    sha=$(git ls-remote "https://github.com/$repo" HEAD 2>/dev/null | awk 'NR==1{print $1}')
                    if [[ -n $sha ]]; then
                        cache[$repo]=$sha
                    else
                        cache[$repo]=FAIL
                        rc=1
                        print -u2 "bump-locks: WARNING: git ls-remote failed for $repo — pin left unchanged"
                    fi
                fi
                [[ ${cache[$repo]} != FAIL ]] && line=${line/pin:[[:xdigit:]]##/pin:${cache[$repo]}}
            fi
            out+=$line
        done < $f
        # Atomic write: a truncating `> $f` could leave a half-written manifest
        # if the shell dies mid-write. Write a sibling temp and rename it over
        # $f (same dir, so the rename is atomic) — $f is then always either the
        # old file or the fully-written new one, never a partial.
        local tmp=$f.bump.$$
        if print -rl -- "${out[@]}" > $tmp && mv -f -- $tmp $f; then
            :
        else
            rm -f -- $tmp
            print -u2 "bump-locks: ERROR: failed to write $f"
            return 1
        fi
    else
        print -u2 "bump-locks: skipping plugins ($f not readable)"
        rc=1
    fi
    print "==> chezmoi re-add"
    chezmoi re-add ~/.config/nix-profile/flake.lock $f || {
        rc=1
        print -u2 "bump-locks: WARNING: chezmoi re-add failed"
    }
    if (( rc )); then
        print -u2 "bump-locks: FINISHED WITH ERRORS — some pins were left unchanged (see warnings above)."
        print -u2 "Nothing was committed. Review carefully: chezmoi cd && git diff"
        return $rc
    fi
    # Commit only the two files this function re-added, by their source paths —
    # `git commit -- <paths>` so an unrelated edit sitting in the working tree
    # (or staged) never rides along in a "deps: bump" commit. Never push:
    # bumping is deliberate, publishing it to the fleet is a separate decision.
    print "==> git commit"
    local src=$(chezmoi source-path)
    local -a paths
    paths=(${(f)"$(chezmoi source-path ~/.config/nix-profile/flake.lock $f)"})
    if [[ -z $src ]] || (( ! $#paths )); then
        print -u2 "bump-locks: WARNING: could not resolve chezmoi source paths — nothing committed."
        print -u2 "Commit by hand: chezmoi cd && git diff"
        return 1
    fi
    if git -C $src diff --quiet HEAD -- $paths; then
        print "bump-locks: locks already at upstream HEAD — nothing to commit."
        return 0
    fi
    git -C $src commit -q -m "deps: bump flake.lock + plugin pins" -- $paths || {
        print -u2 "bump-locks: WARNING: git commit failed — the bump is still in the working tree."
        print -u2 "Commit by hand: chezmoi cd && git diff"
        return 1
    }
    print "bump-locks: flake.lock + plugin pins bumped and committed (not pushed)."
    print "Review: chezmoi cd && git show    Publish: git push"
}

# yazi wrapper: cd shell to whatever directory yazi was in when you quit.
# Without this, quitting yazi leaves you in the dir you started from,
# defeating the point of using it as a navigator. Based on the canonical
# wrapper (yazi-rs.github.io/docs/quick-start#shell-wrapper), hardened
# below against mktemp and cd failures. Named yz to avoid colliding with
# vim-yank muscle memory; type yz to launch.
function yz() {
  # Split declaration from assignment: `local tmp="$(mktemp …)"` always
  # returns 0 (the `local` succeeds), so a mktemp failure (broken TMPDIR)
  # would be masked and yazi would run with an empty --cwd-file=, then
  # `$(< "")` errors. Capture the status and bail instead.
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")" || return
  yazi "$@" --cwd-file="$tmp"
  # Preserve Yazi's exit status: the cd/rm below would otherwise make `rm` the
  # function's return value, masking a Yazi failure as success.
  local rc=$?
  # Fold a failed cd into rc too — changing to yazi's final dir is the whole
  # point of the wrapper, so a cd that fails must not report success.
  if cwd="$(< "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd" || rc=$?
  fi
  rm -f -- "$tmp"
  return $rc
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
