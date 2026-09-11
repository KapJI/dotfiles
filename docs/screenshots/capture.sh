#!/usr/bin/env bash
# Prepare the README screenshots one scene at a time.
#
# Opens a single 120x32 WezTerm window in the main checkout, with the hostname
# shown as "macbook", sets up a scene, and waits. You capture the window with
# Cmd+Shift+4, Space, click, then press Enter here; the newest PNG in the macOS
# screenshot folder is converted to docs/screenshots/<scene>.webp and the next
# scene is prepared. The window closes when the script exits.
#
#   docs/screenshots/capture.sh            # all scenes
#   docs/screenshots/capture.sh nvim yazi  # only these
#
# SHOTS_DIR overrides the folder screenshots are read from (default: the
# com.apple.screencapture location, or ~/Desktop). SHOW_TEXT=1 prints the
# window's text at each prompt, to check a scene before capturing it.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
# The window runs in the main checkout, so the prompt shows the canonical
# path and branch even when this script is run from a worktree.
cwd=$(cd "$(git -C "$repo" rev-parse --git-common-dir)/.." && pwd)
shots=${SHOTS_DIR:-$(defaults read com.apple.screencapture location 2>/dev/null || echo "$HOME/Desktop")}
shots=${shots/#\~/$HOME}

wezterm --config initial_cols=120 --config initial_rows=32 \
    --config 'set_environment_variables={HOST="macbook"}' \
    start --always-new-process --cwd "$cwd" >/dev/null 2>&1 &
echo "window cwd: $cwd"
gui=$!
# lazygit runs in a throwaway single-branch clone, so its branch panel shows
# main and nothing else.
clone=$(mktemp -d)/chezmoi
trap 'kill $gui 2>/dev/null; rm -rf "$(dirname "$clone")"' EXIT
git clone -q --branch main --single-branch "$cwd" "$clone"
export WEZTERM_UNIX_SOCKET="$HOME/.local/share/wezterm/gui-sock-$gui"
for _ in $(seq 40); do [ -S "$WEZTERM_UNIX_SOCKET" ] && break; sleep 0.25; done
sleep 2
pane=$(wezterm cli list --format json | jq -r '.[0].pane_id')

send() { wezterm cli send-text --no-paste --pane-id "$pane" "$1"; }
clear_screen() { send $'\x0c'; sleep 0.3; }
keys() { local k; for k in "$@"; do send "$k"; sleep 0.1; done; }
wait_for() { # wait_for <grep pattern>: poll the pane text until it appears
    for _ in $(seq 40); do
        wezterm cli get-text --pane-id "$pane" | grep -c -- "$1" >/dev/null && return 0
        sleep 0.25
    done
    echo "timed out waiting for: $1; the window shows:" >&2
    wezterm cli get-text --pane-id "$pane" | grep -v '^\s*$' >&2
    return 1
}

scene_shell() {
    clear_screen
    send $'l --no-user home\n'
    wait_for 'dot_zshenv.tmpl'
}
scene_nvim() {
    clear_screen
    send $'nvim home/.data/packages.yaml\n'
    wait_for 'NORMAL'
    # The picker is a terminal buffer running sh; nvim would retitle the tab
    # "sh". Freeze the title on the file name first.
    send $':set notitle\r'
    send $':FzfLua live_grep\r'
    wait_for 'Grep'
    send 'is_desktop'
    wait_for 'dot_zshrc.tmpl'
    sleep 1
}
leave_nvim() { send $'\e'; sleep 0.3; send $':qa!\r'; }
scene_yazi() {
    clear_screen
    send $'yazi home/dot_config/nvim/lua/plugins\n'
    wait_for 'aerial.lua'
    keys j j j j j j j j j j j
    wait_for 'NORMAL.*flash.lua'
    sleep 0.5
}
leave_yazi() { send q; }
scene_lazygit() {
    clear_screen
    send "lazygit -p $clone"$'\n'
    wait_for 'Donate'
    send 4
    sleep 0.3
    # Jump to a commit whose diff reads well: a manifest key plus the Brewfile
    # template that consumes it. HEAD is usually a one-liner.
    send '/'
    sleep 0.3
    send '8c2dfbd'
    sleep 0.3
    send $'\r'
    sleep 0.3
    send $'\e'
    sleep 0.3
    send $'\r'
    wait_for 'Diff files (8c2dfbd'
    sleep 0.5
}
leave_lazygit() { send $'\e'; sleep 0.3; send q; }

import() { # import <scene> <marker file>: newest PNG captured after the marker
    local src dst
    src=$(find "$shots" -name '*.png' -newer "$2" -print0 | xargs -0 ls -t 2>/dev/null | head -1)
    [ -n "$src" ] || { echo "no new screenshot in $shots, skipped $1" >&2; return 0; }
    dst="$here/$1.webp"
    # 820 CSS px in the README, 2x for retina. Lossless suits flat terminal
    # colours; fall back to lossy if it would trip check-added-large-files.
    magick "$src" -resize '1640x>' -strip -define webp:lossless=true "$dst"
    if [ "$(stat -f %z "$dst")" -gt 500000 ]; then
        magick "$src" -resize '1640x>' -strip -quality 90 "$dst"
    fi
    echo "$1: $(basename "$src") -> ${dst#"$repo"/} ($(du -h "$dst" | cut -f1))"
}

scenes=("$@")
[ $# -gt 0 ] || scenes=(shell nvim yazi lazygit)
for s in "${scenes[@]}"; do
    "scene_$s"
    marker=$(mktemp)
    title=$(wezterm cli list --format json | jq -r '.[0].title')
    echo "[$s] ready (tab title: $title)"
    [ -z "${SHOW_TEXT:-}" ] || wezterm cli get-text --pane-id "$pane" | grep -v '^\s*$' | cut -c1-110
    read -r -p "Cmd+Shift+4, Space, click the window, then Enter here: " _
    import "$s" "$marker"
    rm -f "$marker"
    if type "leave_$s" >/dev/null 2>&1; then "leave_$s"; sleep 0.5; fi
done
