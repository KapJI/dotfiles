# Make plugin folder names pretty
zstyle ':antidote:bundle' use-friendly-names 'yes'

# Skip the security audit on every shell start. With this flag,
# zephyr runs `compinit` fully at most once per N hours (Nmh-N
# patched below) and uses the faster `compinit -C` for every shell
# start in between. The chezmoi run_onchange hooks (nix sync, brew,
# antidote update) and the bundle-regen branch below invalidate the
# compdump cache when fpath actually changes.
zstyle ':zephyr:plugin:completion' use-cache 'yes'

# Silence Oh My Zsh's own updater. getantidote/use-omz sources OMZ's
# tools/check_for_upgrade.sh, whose `mode` defaults to `prompt`: every
# UPDATE_ZSH_DAYS (13) it asks to update and, on accept, `git pull`s the
# antidote-owned ohmyzsh clone — a second update path that fights the
# weekly `antidote update` in run_onchange_after_80. Must be set before
# the bundle `source` below, since use-omz runs during that source.
zstyle ':omz:update' mode disabled

# Static-load mode (antidote's recommended fast path, ~30ms saving vs
# `antidote load`):
#   1. Regenerate the static bundle (.zsh_plugins.zsh) only when the
#      plugin list (.zsh_plugins.txt) is newer than it.
#   2. Compile the bundle to .zwc on change so zsh reads bytecode
#      directly on subsequent startups (~30-60ms additional saving).
#   3. Source the bundle. zsh prefers .zwc when it's newer than the
#      .zsh source, so the source line transparently picks bytecode.
fpath=($ZDOTDIR/antidote/functions $fpath)
autoload -Uz antidote

# add-zsh-hook ships with zsh, but it only becomes usable once something
# autoloads it — and today that "something" is a plugin in the bundle.
# Several config.d files call add-zsh-hook before any such plugin is
# guaranteed loaded (auto_title.zsh runs before tmux_osc133.zsh's own
# autoload), and the degraded no-plugins path below loads no bundle at
# all. Autoload it here, unconditionally and ahead of the bundle, so
# those callers never hit command-not-found. Idempotent and fork-free.
autoload -Uz add-zsh-hook

zsh_plugins=$ZDOTDIR/.zsh_plugins.zsh
zsh_plugins_txt=$ZDOTDIR/.zsh_plugins.txt

if [[ ! -e $zsh_plugins || $zsh_plugins_txt -nt $zsh_plugins ]]; then
    # Generate into a temp file and rename atomically. Writing the live
    # bundle in place means an interrupted `antidote bundle` (or two
    # shells racing this branch) can leave it truncated — and because the
    # truncated file is then newer than the .txt, this guard skips regen
    # and `source`s the broken bundle on every subsequent startup. The
    # per-PID temp keeps racing shells from clobbering each other; mv
    # picks one winner atomically. Keep the previous bundle on failure.
    # The mv is checked too (read-only ZDOTDIR, full disk): an unchecked
    # mv failure would drop the compdump for a plugin set that never
    # actually changed and pretend the regen landed.
    if antidote bundle <"$zsh_plugins_txt" >| "$zsh_plugins.tmp.$$" \
            && mv -f -- "$zsh_plugins.tmp.$$" "$zsh_plugins"; then
        # Plugin set changed (added/removed/reordered) — the cached
        # compdump may reference completion functions from plugins that
        # are no longer loaded. Drop it so zephyr's run_compinit does a
        # full rebuild against the new fpath. (N) glob qualifier =
        # expand to nothing if no match, instead of zsh's default error.
        rm -f -- "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/"zcompdump*(N)
    else
        rm -f -- "$zsh_plugins.tmp.$$"
        print -u2 "antidote: bundle regen failed; keeping previous $zsh_plugins"
    fi
fi

# On a fresh host (or after bundle loss) a failed regen leaves nothing to
# load. Skip compile+source with one clear message instead of cascading a
# zcompile error, a source error, and undefined-function noise from every
# later config file that assumes the plugins loaded. The bundle stays
# absent, so the next shell retries the regen from scratch.
if [[ -e $zsh_plugins ]]; then
    # Recompile when the source is newer OR the existing .zwc can't be loaded
    # by the running zsh. zsh embeds its full version in the .zwc and silently
    # ignores a mismatched one — reparsing the .zsh text every startup, no
    # error — and since a zsh upgrade leaves that stale .zwc still newer than
    # its unchanged source, the mtime check alone would keep the dead cache
    # forever, quietly losing the bytecode savings until the next bundle regen.
    # `zcompile -t` is a fork-free header read that applies zsh's own compat
    # rule (and catches a truncated/corrupt .zwc too). Its success line goes to
    # STDOUT, so silence both streams, not just stderr.
    if [[ ! -e $zsh_plugins.zwc || $zsh_plugins -nt $zsh_plugins.zwc ]] \
            || ! zcompile -t -- $zsh_plugins.zwc >/dev/null 2>&1; then
        zcompile -R -- $zsh_plugins.zwc $zsh_plugins
    fi
    source $zsh_plugins
else
    print -u2 "antidote: no plugin bundle to load; starting without plugins"
fi
unset zsh_plugins zsh_plugins_txt

# Stretch zephyr's compinit cache window from the hardcoded 20 hours
# to 1 week. The chezmoi run_onchange hooks already invalidate the
# compdump whenever fpath actually changes (nix profile sync, brew
# bundle, antidote update); the bundle-regen branch above catches
# local plugin-list edits. The time-based fallback is just a safety
# net for completion-source changes that bypass all of those.
#
# zephyr defers run_compinit to post_zshrc (precmd hook) by default
# — `immediate` zstyle is NOT set — so the function runs after this
# patch lands, picking up the new constant. The `Nmh-20` guard means
# this no-ops silently if upstream zephyr changes the format.
#
# HISTORY — read before "fixing" this patch or the deferral:
# an earlier attempt at this patch coincided with broken tab
# completion; the real culprit was plugin load order (fsh loading
# before fzf-tab/compinit), fixed in 4d0fed2, and the patch was then
# deliberately reintroduced (b3cad0a). Two rules keep it working:
#   1. Do NOT set `zstyle ':zephyr:plugin:completion' immediate` —
#      that runs compinit during the bundle source above, before this
#      patch exists, silently shrinking the window back to 20h
#      (b3cad0a removed `immediate` for exactly this reason).
#   2. If tab completion breaks, suspect plugin load order in
#      .zsh_plugins.txt (see its header) before suspecting this patch.
if (( ${+functions[run_compinit]} )); then
    _patched=$(functions run_compinit)
    if [[ $_patched == *Nmh-20* ]]; then
        eval "${_patched//Nmh-20/Nmh-168}"
    fi
    unset _patched
fi
