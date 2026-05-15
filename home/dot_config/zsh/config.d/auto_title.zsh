# Display a shortened PWD in the tmux window name (and terminal tab).
# Style: p10k's truncate_with_folder_marker + truncate_to_unique.
#
#   ~/Project/github/dotfiles/home/dot_config/nvim
#     → dotfiles/h/d/nvim
#
#   ~/Documents/foo/bar  (no .git anywhere on the way up)
#     → ~/D/f/bar
#
# Algorithm:
#   1. Walk up from PWD looking for `.git`. If found, anchor on that
#      repo: full repo dir name + the in-repo path, with intermediates
#      shrunk starting siblings from the repo root.
#   2. Otherwise, shrink the home-relative path (or absolute path if
#      we're outside HOME), starting siblings from HOME / `/`.
#   3. In every case the LAST segment (current dir) is kept full; only
#      intermediate segments are truncated.
#   4. Each intermediate segment is shortened to the shortest prefix
#      that uniquely identifies it among entries in its parent dir
#      (GLOBDOTS is on, so hidden siblings are considered too).

# Shortest unique prefix of $2 within $1.
_atit_unique_prefix() {
    local parent=$1 target=$2 len prefix matches
    for (( len = 1; len < ${#target}; len++ )); do
        prefix=${target[1,$len]}
        matches=( $parent/${prefix}*(N) )
        (( ${#matches} <= 1 )) && { print -r -- $prefix; return }
    done
    print -r -- $target
}

# Shrink a relative path's intermediate segments against $1=base dir,
# keeping the last segment full.
_atit_shrink_rel() {
    local base=$1 rel=$2
    local -a segments=( ${(s:/:)rel} )
    local n=${#segments} i seg result=''
    for (( i = 1; i <= n; i++ )); do
        seg=$segments[$i]
        if (( i == n )); then
            result+=$seg
        else
            result+="$(_atit_unique_prefix $base $seg)/"
        fi
        base=$base/$seg
    done
    print -r -- $result
}

_atit_short_pwd() {
    # 1. Closest .git ancestor.
    local dir=$PWD root=''
    while [[ -n $dir && $dir != / ]]; do
        [[ -e $dir/.git ]] && { root=$dir; break }
        dir=${dir%/*}
    done
    if [[ -n $root ]]; then
        local name=${root:t}
        [[ $PWD == $root ]] && { print -r -- $name; return }
        print -r -- "$name/$(_atit_shrink_rel $root ${PWD#$root/})"
        return
    fi
    # 2. Outside any repo — home-relative or absolute.
    [[ $PWD == $HOME ]] && { print -r -- '~'; return }
    if [[ $PWD == $HOME/* ]]; then
        print -r -- "~/$(_atit_shrink_rel $HOME ${PWD#$HOME/})"
    else
        print -r -- "/$(_atit_shrink_rel / ${PWD#/})"
    fi
}

_set_term_title_precmd() {
    local short=$(_atit_short_pwd)
    local full=${PWD/#$HOME/\~}
    # Folder glyph prefix marks "a shell sitting at a prompt in this
    # directory" — visually distinct from running-program titles,
    # which the preexec hook below prefixes with a gear glyph.
    title " $short" "$full"
}

add-zsh-hook precmd _set_term_title_precmd

# Prefix running-command titles with a gear glyph so a tool running
# in a pane is instantly distinguishable from a shell idling in a
# directory (folder glyph, above). Runs after OMZ's
# omz_termsupport_preexec and overrides its plain title. The
# CMD-extraction mirrors OMZ's: the first command-line word that
# isn't an env-assignment, a wrapper (sudo/ssh/…), or a -flag.
_atit_preexec_glyph() {
    [[ ${DISABLE_AUTO_TITLE:-} == true ]] && return
    local cmd="${1[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%}"
    title " $cmd"
}

add-zsh-hook preexec _atit_preexec_glyph

# Inside tmux, override OMZ's `title` (from path:lib/termsupport.zsh)
# to always emit OSC 2. OMZ uses the screen DCS escape `\ek...\e\\`
# under TERM=tmux*, which sets the WINDOW name directly (or is
# blocked entirely by `allow-rename off`) — neither does what we want.
# OSC 2 instead updates the PANE's title, which tmux's
# `automatic-rename-format = '#{pane_title}'` turns into the window
# name. Net effect: each split tracks its own title and the window
# name follows the focused split.
#
# The override is gated on $TMUX so non-tmux contexts — local wezterm
# / ghostty / kitty etc. — keep OMZ's original behaviour, which is
# already OSC 2/1 for xterm-class terminals and natively supports
# per-pane tab title tracking in those terminals.
if [[ -n $TMUX ]]; then
    function title {
        [[ ${DISABLE_AUTO_TITLE:-} == true ]] && return
        [[ $EMACS == *term* ]] && return
        : ${2=$1}
        # Inside tmux, OSC 2 → pane_title → window name (via our
        # automatic-rename hooks). Emit the SHORT string here so the
        # window name is concise; OMZ's convention of putting the long
        # version in OSC 2 makes sense for non-tmux terminals but
        # produces a full-path window name in tmux.
        print -Pn "\e]2;${1:q}\a"
        print -Pn "\e]1;${1:q}\a"
    }
fi

# `edit-command-line` (bound to Alt+e / ^X^E) launches $EDITOR, which
# sets its own terminal title. On return it lands on the SAME prompt —
# no `precmd` fires — so the title stays stuck on the editor's. Wrap
# the widget to re-emit the directory title once the editor exits.
# `key_bindings.zsh` (sourced later) points Alt+e and ^X^E at this
# wrapper instead of the bare `edit-command-line` widget.
_atit_edit_command_line() {
    zle edit-command-line
    _set_term_title_precmd
}
zle -N _atit_edit_command_line
