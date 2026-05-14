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
    title "$short" "$full"
}

add-zsh-hook precmd _set_term_title_precmd
