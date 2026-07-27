#!/bin/sh
# git fixup <commit> [extra git-commit args...]
#
# Create a fixup! commit for <commit> from the currently-staged changes,
# then fold it in via a non-interactive autosquash rebase onto <commit>^.
#
# Usage:
#   git add -p                 # stage the correction
#   git fixup HEAD~2           # fix up an earlier commit (SHA or ref)
#   git fixup abc123 --no-verify
#
# Invoked as `!sh ~/bin/git-fixup.sh` from the `fixup` alias, so this must
# stay POSIX sh (no bash arrays). "$@" preserves each extra arg verbatim —
# the previous version built a command string and re-ran it through
# `sh -c`, which word-split quoted values (e.g. `-m 'two words'` reached
# git as `-m two words`) and let metacharacters become shell syntax.
#
# GIT_DIR / GIT_WORK_TREE are honoured by git from the environment
# directly, so they don't need to be threaded through explicitly.
set -eu

if [ "$#" -eq 0 ]; then
    echo "usage: git fixup <commit> [git-commit args...]" >&2
    exit 1
fi

target=$(git rev-parse "$1")
shift

git commit --fixup="$target" "$@"
EDITOR=true git rebase -i --autostash --autosquash "$target^"
