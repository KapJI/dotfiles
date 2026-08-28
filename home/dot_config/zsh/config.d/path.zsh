# Set PATH

# Keep first occurrence of each entry
typeset -U path

# Anonymous function so `extra` stays local — at file scope `local` is
# just `typeset` and would leak a global into every shell.
() {
    local -a extra=(
        "$HOME/bin"
        "$HOME/.local/bin"
        "$HOME/.npm/bin"
        "$HOME/.iterm2"
        "$HOME/.cargo/bin"
        "$HOME/.yarn/bin"
        "$HOME/.config/yarn/global/node_modules/.bin"
    )

    if [ "$MACOS" = true ]; then
        extra+="/opt/homebrew/bin"
    fi

    extra+="/usr/local/bin"

    # Re-assert the nix profile ahead of the system dirs.
    #
    # /etc/zshrc's nix snippet prepends them ONCE per process tree: it guards
    # on $__ETC_PROFILE_NIX_SOURCED, which is exported, so every nested shell
    # skips it. /etc/zprofile's path_helper, by contrast, runs in EVERY login
    # shell and rebuilds PATH with /etc/paths + /etc/paths.d/* first and the
    # inherited entries appended after. Net effect in a nested login shell — a
    # herdr/tmux pane, `ssh` to localhost, a bare `zsh -l` — the nix dirs are
    # still on PATH but sink below /usr/bin, so `git`, `jq`, `make`, `zsh`,
    # `hostname`, `ping`, `traceroute`, `whois` … silently resolve to the
    # macOS copies while the top-level shell gets the profile's. Listing them
    # here restores the intended order; `typeset -U path` above drops the
    # demoted duplicates further down.
    #
    # Sourced from $NIX_PROFILES (set by the same nix profile script) rather
    # than hardcoded, so this tracks nix's own idea of the profile list on
    # both macOS and Linux. Reversed — nix puts the user profile ahead of the
    # default one in PATH, the opposite of the order it lists them in.
    local profile
    for profile in ${(Oa)${(z)NIX_PROFILES}}; do
        [[ -d $profile/bin ]] && extra+="$profile/bin"
    done

    path=( $extra $path )
}

export PATH
