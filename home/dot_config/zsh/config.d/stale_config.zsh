# p10k segment `zsh_stale`: a yellow `reload` in the right prompt once any zsh
# config file is modified after this shell loaded it, in every open pane, until
# `reload` (or a new shell) picks the change up. chezmoi only rewrites a file
# whose content changed, so a newer mtime means a real change; hand edits and
# antidote rebuilding .zsh_plugins.zsh count too. Sourced after antidote.zsh,
# so a bundle rebuilt during this shell's own startup does not flag it.
#
# p10k calls prompt_zsh_stale on every prompt: one glob over ~30 files, ~0.2 ms.
zmodload zsh/datetime
typeset -g _zsh_config_loaded_at=$EPOCHSECONDS

prompt_zsh_stale() {
    local age=$(( EPOCHSECONDS - _zsh_config_loaded_at ))
    # (ms-N): modified less than N seconds ago, i.e. after this shell started.
    local -a changed=(
        $HOME/.zshenv $ZDOTDIR/.zshrc $ZDOTDIR/.zsh_plugins.zsh
        $ZDOTDIR/{config.d,custom_completion}/**/*
    )
    changed=( ${^changed}(N.ms-$age) )
    (( $#changed )) && p10k segment -f yellow -t reload
}
