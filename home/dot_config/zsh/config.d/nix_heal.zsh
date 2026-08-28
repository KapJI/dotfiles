# Repair a shell that started before /nix was mounted.
#
# /nix is an encrypted APFS volume, mounted at boot by `determinate-nixd init`
# from the systems.determinate.nix-store LaunchDaemon — RunAtLoad, with NO
# ordering relationship to login items. A terminal restored at login regularly
# wins that race. /etc/zshrc's nix block is guarded by
#     [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]
# so when the volume isn't up yet it is skipped in silence: no error, and
# .zshrc still runs to completion, so the shell looks perfectly normal. What it
# actually has is no nix on $PATH, no NIX_PROFILES / NIX_SSL_CERT_FILE /
# XDG_DATA_DIRS, no `z`/`zi`, no fzf widgets, no completions for any nix tool,
# and `git` silently resolving to /usr/bin/git. Measured on the 2026-08-28
# 15:04:59 boot: shell started 15:06:34, /nix mounted 15:06:43.8 — lost by 9s.
#
# Waiting for the mount inside .zshrc would block the first login shell for the
# ~10-30s it takes, on every boot, to fix a shell that may never be used. So
# instead: notice the situation, retry once per prompt, and redo the missing
# work as soon as the volume appears. One [[ -e ]] per prompt, and only in the
# already-broken case — a healthy shell has __ETC_PROFILE_NIX_SOURCED set and
# never arms the hook at all.
#
# The function is left defined either way: in a shell that raced and was
# already healed (or one where the guard below declined to arm), running
# `_nix_profile_heal` by hand does the same repair.
_nix_profile_heal() {
    local hook=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    if [[ ! -e $hook ]]; then
        # Still not mounted — try again at the next prompt, but give up
        # eventually so a host where /nix is simply gone doesn't carry the hook
        # for the life of the shell. $SECONDS is this shell's own age, and the
        # deadline is checked only AFTER the mount test above, so a first
        # prompt typed hours after boot still heals.
        (( SECONDS > 600 )) && add-zsh-hook -d precmd _nix_profile_heal
        return 0
    fi
    add-zsh-hook -d precmd _nix_profile_heal

    # Do what /etc/zshrc's nix block would have done, then re-run the config
    # that consumed it. Each file below is safe to source twice: path.zsh
    # rebuilds $path under `typeset -U`, completion.zsh only prepends fpath
    # entries and sets zstyles, and plugins/fzf.zsh already guards its widget
    # wrapper against re-wrapping (see the comment there).
    source $hook                                 # PATH + NIX_* + XDG_DATA_DIRS
    source $ZDOTDIR/config.d/path.zsh            # canonical order: extra, nix, system
    source $ZDOTDIR/config.d/completion.zsh      # fpath += the nix site-functions dirs
    fpath=( ${(u)fpath} )                        # drop what the re-source duplicated
    source $ZDOTDIR/config.d/plugins/fzf.zsh     # Ctrl-R / Ctrl-T / Alt-C
    source $ZDOTDIR/config.d/plugins/zoxide.zsh  # z / zi
    rehash                                       # forget the cached /usr/bin/git etc.

    # Rebuild the completion dump against the now-complete fpath, reusing the
    # framework's own $ZSH_COMPDUMP so this stays the single dump every other
    # consumer reads. Skipped rather than guessing a path if it isn't set.
    if [[ -n ${ZSH_COMPDUMP-} ]]; then
        rm -f -- $ZSH_COMPDUMP
        autoload -Uz compinit && compinit -d $ZSH_COMPDUMP
    fi

    print -u2 "zsh: nix profile was missing at startup (/nix mounted late) — restored: PATH, z/zi, fzf, completions."
}

# Arm only when nix belongs on this host AND demonstrably has not loaded yet.
# Testing the hook's absence — not just the unset guard variable — keeps this
# to the boot race we actually diagnosed: on any host where the nix profile
# script is already readable, behaviour is unchanged. The marker checks cover
# the window before the volume mounts, when /nix may not even exist as a
# mountpoint yet; both installers leave their mount daemon on the boot volume.
if [[ -z ${__ETC_PROFILE_NIX_SOURCED-} \
        && ! -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]] \
        && [[ -d /nix \
           || -e /Library/LaunchDaemons/systems.determinate.nix-store.plist \
           || -e /Library/LaunchDaemons/org.nixos.darwin-store.plist ]]; then
    add-zsh-hook precmd _nix_profile_heal
fi
