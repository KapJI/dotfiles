# Make plugin folder names pretty
zstyle ':antidote:bundle' use-friendly-names 'yes'

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
fi

if [[ ! -e $zsh_plugins.zwc || $zsh_plugins -nt $zsh_plugins.zwc ]]; then
    zcompile -R -- $zsh_plugins.zwc $zsh_plugins
fi

source $zsh_plugins
unset zsh_plugins zsh_plugins_txt
