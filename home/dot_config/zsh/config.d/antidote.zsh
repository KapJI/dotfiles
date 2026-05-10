# Make plugin folder names pretty
zstyle ':antidote:bundle' use-friendly-names 'yes'

# Skip the security audit on every shell start. With this flag,
# zephyr runs `compinit` fully at most once per N hours (Nmh-N
# patched below) and uses the faster `compinit -C` for every shell
# start in between. The chezmoi run_onchange hooks (nix sync, brew,
# antidote update) and the bundle-regen branch below invalidate the
# compdump cache when fpath actually changes.
zstyle ':zephyr:plugin:completion' use-cache 'yes'

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

zsh_plugins=$ZDOTDIR/.zsh_plugins.zsh
zsh_plugins_txt=$ZDOTDIR/.zsh_plugins.txt

if [[ ! -e $zsh_plugins || $zsh_plugins_txt -nt $zsh_plugins ]]; then
    antidote bundle <$zsh_plugins_txt >| $zsh_plugins
    # Plugin set changed (added/removed/reordered) — the cached
    # compdump may reference completion functions from plugins that
    # are no longer loaded. Drop it so zephyr's run_compinit does a
    # full rebuild against the new fpath. (N) glob qualifier =
    # expand to nothing if no match, instead of zsh's default error.
    rm -f -- "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/"zcompdump*(N)
fi

if [[ ! -e $zsh_plugins.zwc || $zsh_plugins -nt $zsh_plugins.zwc ]]; then
    zcompile -R -- $zsh_plugins.zwc $zsh_plugins
fi

source $zsh_plugins
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
if (( ${+functions[run_compinit]} )); then
    _patched=$(functions run_compinit)
    if [[ $_patched == *Nmh-20* ]]; then
        eval "${_patched//Nmh-20/Nmh-168}"
    fi
    unset _patched
fi
