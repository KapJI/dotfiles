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
# exercised on the host that actually has it. A template that fails to render
# here (e.g. it targets another OS) is noted and skipped, not failed — chezmoi
# apply is the real template-validity gate. Exits non-zero if any check fails.
set -u

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$here/../.." && pwd)
rc=0

render() { chezmoi execute-template <"$1"; }
nonblank() { [ -n "$(printf '%s' "$1" | tr -d '[:space:]')" ]; }

echo "== zsh -n =="
for f in $(find "$root/home/dot_config/zsh" -name '*.zsh' -type f | sort); do
    if ! out=$(zsh -n "$f" 2>&1); then
        printf 'FAIL zsh -n: %s\n%s\n' "$f" "$out"
        rc=1
    fi
done
for f in $(find "$root/home/dot_config/zsh" -name '*.tmpl' -type f | sort); do
    if ! r=$(render "$f" 2>&1); then
        printf 'SKIP (render failed here): %s\n' "$f"
        continue
    fi
    if ! out=$(printf '%s\n' "$r" | zsh -n 2>&1); then
        printf 'FAIL zsh -n (rendered): %s\n%s\n' "$f" "$out"
        rc=1
    fi
done

echo "== shellcheck =="
if command -v shellcheck >/dev/null 2>&1; then
    for f in $(find "$root/home/.chezmoiscripts" -name '*.sh.tmpl' -type f | sort); do
        if ! r=$(render "$f" 2>&1); then
            printf 'SKIP (render failed here): %s\n' "$f"
            continue
        fi
        nonblank "$r" || continue # host-gated script renders empty here
        if ! out=$(printf '%s\n' "$r" | shellcheck - 2>&1); then
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
