#!/usr/bin/env sh
# Pre-commit smoke checks for shell + tmux sources (companion to tests/nvim).
#
#   - zsh -n on every zsh config file. Non-templated *.zsh are checked
#     directly; *.tmpl are rendered with `chezmoi execute-template` first,
#     because a raw {{…}} template is not valid zsh.
#   - shellcheck on every rendered *.sh.tmpl chezmoi script. Skipped with a
#     note if shellcheck is not installed (it ships via .data/packages.yaml).
#   - tmux config syntax: load the rendered .tmux.conf in a throwaway server on
#     a private socket, then tear it down. Skipped if tmux is absent or the
#     config renders empty (it is Linux-server-only, so it renders to nothing
#     on macOS/desktop hosts).
#
# Rendering uses the committing host's chezmoi data, so a host-gated branch is
# exercised on the host that actually has it. A host-gated template renders to
# EMPTY output (exit 0), which the checks tolerate; a template that FAILS to
# render is a real bug (it would fail chezmoi apply too) and is a failure, not
# a skip. Exits non-zero if any check fails.
set -u

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$here/../.." && pwd)
rc=0

render() { chezmoi execute-template <"$1"; }
nonblank() { [ -n "$(printf '%s' "$1" | tr -d '[:space:]')" ]; }

echo "== zsh -n =="
# Every zsh source: config.d + completions under dot_config/zsh, PLUS the
# home-root startup files (~/.zshenv etc.) that live at home/ root, not under
# zsh/ — a syntax error there breaks every shell. Templates are rendered with
# chezmoi first (a raw {{…}} template is not valid zsh).
for f in $(
    {
        find "$root/home/dot_config/zsh" \( -name '*.zsh' -o -name '*.tmpl' \) -type f
        find "$root/home" -maxdepth 1 -type f -name 'dot_z*'
    } | sort -u
); do
    case "$f" in
    *.tmpl)
        if ! r=$(render "$f" 2>&1); then
            printf 'FAIL render: %s\n%s\n' "$f" "$r"
            rc=1
            continue
        fi
        if ! out=$(printf '%s\n' "$r" | zsh -n 2>&1); then
            printf 'FAIL zsh -n (rendered): %s\n%s\n' "$f" "$out"
            rc=1
        fi
        ;;
    *)
        if ! out=$(zsh -n "$f" 2>&1); then
            printf 'FAIL zsh -n: %s\n%s\n' "$f" "$out"
            rc=1
        fi
        ;;
    esac
done

echo "== shellcheck =="
if command -v shellcheck >/dev/null 2>&1; then
    for f in $(find "$root/home/.chezmoiscripts" -name '*.sh.tmpl' -type f | sort); do
        # Another OS's scripts can call that OS's binaries at *render* time
        # (macos/50 runs sw_vers). chezmoi doesn't render them on this host
        # either — .chezmoiignore drops the directory — so leave them be.
        case "$f" in
        */macos/*) [ "$(uname -s)" = Darwin ] || continue ;;
        */linux/*) [ "$(uname -s)" = Linux ] || continue ;;
        esac
        if ! r=$(render "$f" 2>&1); then
            printf 'FAIL render: %s\n%s\n' "$f" "$r"
            rc=1
            continue
        fi
        nonblank "$r" || continue # host-gated script renders empty here
        # -e SC2317: a host-gated template can render an early `exit 0` ahead
        # of the branch this host skips (02-nix-substituters in a container).
        if ! out=$(printf '%s\n' "$r" | shellcheck -e SC2317 - 2>&1); then
            printf 'FAIL shellcheck: %s\n%s\n' "$f" "$out"
            rc=1
        fi
    done
else
    echo "shellcheck not installed — skipping (add via .data/packages.yaml)"
fi

echo "== tmux syntax =="
if command -v tmux >/dev/null 2>&1; then
    if r=$(render "$root/home/dot_tmux.conf.tmpl" 2>/dev/null) && nonblank "$r"; then
        tmp=$(mktemp)
        printf '%s\n' "$r" >"$tmp"
        # Start a throwaway server with NO config (-f /dev/null) on a private
        # socket, then source the rendered .tmux.conf into it. source-file
        # returns non-zero and prints "file:line: …" on a parse or unknown-
        # command error, whereas `new-session -f badfile` starts anyway and
        # exits 0 (it doesn't surface config errors). Plugin run-shell loads
        # are guarded by `test -r`; a missing plugin takes the else branch, so
        # a clean source is the signal we want.
        tmux -L pc-check -f /dev/null new-session -d 2>/dev/null
        if ! out=$(tmux -L pc-check source-file "$tmp" 2>&1); then
            printf 'FAIL tmux source-file: %s\n%s\n' "$root/home/dot_tmux.conf.tmpl" "$out"
            rc=1
        fi
        tmux -L pc-check kill-server 2>/dev/null || true
        rm -f "$tmp"
    else
        echo "tmux config renders empty on this host — skipping"
    fi
else
    echo "tmux not installed — skipping"
fi

if [ "$rc" -eq 0 ]; then
    echo "shell checks: OK"
fi
exit "$rc"
