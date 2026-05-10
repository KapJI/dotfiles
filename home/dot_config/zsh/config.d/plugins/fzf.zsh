# Initialize fzf shell integration (Ctrl+R, Ctrl+T, Alt+C)
eval "$(fzf --zsh)"

# fzf 0.48+ rebinds Tab to its own `fzf-completion` widget here, which
# overrides fzf-tab's binding from antidote. Without `**` trigger,
# fzf-completion falls back to `expand-or-complete` — bypassing fzf-tab's
# direct widget. Point the fallback at fzf-tab-complete so plain Tab goes
# straight to fzf-tab while keeping the `**` trigger for path-finding.
if [[ -n ${widgets[fzf-tab-complete]-} ]]; then
    fzf_default_completion=fzf-tab-complete
fi

# fzf-tab on Linux + wezterm: first Tab printed a newline, second Tab
# fired fzf. Cause: the typeahead-capture line in `-ftb-fzf`
#   _ftb_query+="$(dd bs=1G count=1 status=none iflag=nonblock </dev/tty)"
# reads bytes the *terminal* sent back into /dev/tty (DSR responses,
# OSC echoes from p10k/shell-integration). On the first Tab those
# bytes either stall dd or become escape garbage appended to fzf's
# --query, so fzf bails out before drawing. macOS without coreutils
# escapes this because BSD `dd` doesn't support `iflag=nonblock`, so
# the line errors and `|| true` swallows it.
# Strip the line by reloading -ftb-fzf from source without it. Cost:
# user keystrokes typed during the brief window before fzf draws are
# lost instead of becoming the initial query — acceptable trade.
if (( ${+functions[-ftb-fzf]} )); then
    autoload +X -- -ftb-fzf 2>/dev/null
    if [[ -r ${FZF_TAB_HOME:-/dev/null}/lib/-ftb-fzf ]]; then
        eval "function -ftb-fzf {
$(sed '/iflag=nonblock/d' "$FZF_TAB_HOME/lib/-ftb-fzf")
}"
    fi
fi

# Configure fzf to use fd
export FZF_DEFAULT_COMMAND="fd --type file --color=always --hidden --exclude .git --exclude .hg --exclude node_modules"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# Alt+C → recursive directory picker. Default uses `find`, which is slow
# in deep trees and ignores gitignore; switch to fd for parity with the
# file picker's exclusions.
export FZF_ALT_C_COMMAND="fd --type d --color=always --hidden --exclude .git --exclude .hg --exclude node_modules"
export FZF_DEFAULT_OPTS="--ansi --height=50% --layout=reverse"
# export FZF_DEFAULT_OPTS="--ansi --height=40% --layout=reverse --preview-window 'right:60%' --preview 'if [ -d {} ]; then eza --tree --level=1 --color=always --icons=always {}; elif [ -f {} ]; then head -n 100 {} | chroma --style=emacs --filename={}; else echo {}; fi'"

_fzf_compgen_path() {
    fd --hidden --follow --color=always --exclude ".git" --exclude ".hg" --exclude "node_modules" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
    fd --type d --hidden --follow --color=always --exclude ".git" --exclude ".hg" --exclude "node_modules" . "$1"
}

_fzf_compgen_unalias() {
    tmpfile=$(mktemp /tmp/zsh-complete.XXXXXX)
    alias > "$tmpfile"
    fzf "$@" --preview 'ESCAPED=$(printf "%s=" {} | sed -e '"'"'s/[]\/$*.^[]/\\&/g'"'"'); cat '"$tmpfile"' | grep "^$ESCAPED"'
    rm "$tmpfile"
}

_fzf_comprun() {
    local command=$1
    shift

    case "$command" in
        export|unset) fzf "$@" --preview "eval 'echo \$'{}" ;;
        ssh|telnet)   fzf "$@" --preview 'echo {}' ;;
        unalias)      _fzf_compgen_unalias "$@" ;;
        *)            fzf "$@" ;;
    esac
}

# fzf-tab + FSH workaround: pressing Escape in fzf-tab's popup left
# the prompt without FSH highlighting until the next keystroke.
#
# Cause: fzf-tab invokes the underlying completion widget
# (expand-or-complete) which uses region_highlight internally for
# menu-select; on Escape it clears region_highlight. FSH's
# _zsh_highlight on return sees BUFFER unchanged and skips
# repopulating, leaving the line un-highlighted.
#
# Fix: wrap fzf-tab-complete one more layer to force FSH to
# recompute (by clearing its buffer-cache marker) and force a
# redisplay. Must run AFTER fzf-tab and FSH have wired their
# widgets — the current binding here is FSH's wrap (autosuggest
# adds its own outer wrap later via its precmd hook).
if [[ -n ${widgets[fzf-tab-complete]-} ]]; then
    zle -N _fzf_tab_complete_orig "${widgets[fzf-tab-complete]#user:}"

    _fzf_tab_complete_with_redisplay() {
        zle _fzf_tab_complete_orig -- "$@"
        local ret=$?
        # Trick FSH into re-running its full-line highlighter.
        typeset -g _ZSH_HIGHLIGHT_PRIOR_BUFFER=""
        _zsh_highlight 2>/dev/null
        zle -R
        return $ret
    }
    zle -N fzf-tab-complete _fzf_tab_complete_with_redisplay
fi
