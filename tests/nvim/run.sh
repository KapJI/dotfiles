#!/usr/bin/env sh
# Run the Neovim config test suite headlessly via plenary's busted harness.
# Exits non-zero if any spec fails (checks the exit code AND greps the
# summary, since plenary's headless exit code has been unreliable across
# versions).
set -eu
here="$(cd "$(dirname "$0")" && pwd)" # tests/nvim
init="$here/minimal_init.lua"
spec="$here/spec"

set +e
out="$(nvim --headless --noplugin -u "$init" \
  -c "PlenaryBustedDirectory $spec { minimal_init = '$init', sequential = true }" 2>&1)"
code=$?
set -e

printf '%s\n' "$out"

if [ "$code" -ne 0 ] || printf '%s' "$out" | grep -qE "Tests Failed|Failed *: *[1-9]|Errors *: *[1-9]"; then
  exit 1
fi
