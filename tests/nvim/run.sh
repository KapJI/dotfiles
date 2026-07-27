#!/usr/bin/env sh
# Run the Neovim config test suite headlessly via plenary's busted harness.
# Exits non-zero if any spec fails (checks the exit code AND greps the
# summary, since plenary's headless exit code has been unreliable across
# versions).
set -eu
here="$(cd "$(dirname "$0")" && pwd)" # tests/nvim
init="$here/minimal_init.lua"
spec="$here/spec"

# Isolate from the deployed ~/.config/nvim: point XDG_CONFIG_HOME at an
# empty temp dir so nvim's default runtimepath does NOT include the applied
# config. minimal_init.lua then explicitly adds the SOURCE config, making it
# the only config on the runtimepath — so the suite tests the source of
# truth, not whatever happens to be deployed.
#
# Also point XDG_STATE_HOME at a throwaway dir so swap/shada/log land there
# instead of the real ~/.local/state: in a restricted/read-only environment
# that dir otherwise fails every test with E303 and drops an nvim.log into the
# repo. (minimal_init also disables swap and shada outright — belt and
# suspenders.) XDG_DATA_HOME is left alone so the plenary clone under
# ~/.local/share/nvim is still found.
xdg="$(mktemp -d)"
state="$(mktemp -d)"
trap 'rm -rf "$xdg" "$state"' EXIT

set +e
out="$(XDG_CONFIG_HOME="$xdg" XDG_STATE_HOME="$state" nvim --headless --noplugin -u "$init" \
  -c "PlenaryBustedDirectory $spec { minimal_init = '$init', sequential = true }" 2>&1)"
code=$?
set -e

printf '%s\n' "$out"

if [ "$code" -ne 0 ] || printf '%s' "$out" | grep -qE "Tests Failed|Failed *: *[1-9]|Errors *: *[1-9]"; then
  exit 1
fi
