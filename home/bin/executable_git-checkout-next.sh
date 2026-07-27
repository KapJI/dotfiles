#!/bin/sh
# Check out the child of HEAD along the default branch's first-parent
# history — the counterpart of `git prev` (checkout HEAD^). Used by the
# `git next` alias in .gitconfig. Invoked as `!sh ~/bin/...`, so POSIX sh.
set -eu

# Default branch: origin/HEAD when set, else a local main/master.
# `symbolic-ref --quiet` prints nothing and exits non-zero when origin/HEAD
# is unset — unlike `rev-parse --abbrev-ref origin/HEAD`, which echoes the
# literal string "origin/HEAD" to stdout, so a local-only repo used to end
# up with branch="HEAD" and skip the main/master fallback entirely.
branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
branch=${branch#origin/}
if [ -z "$branch" ]; then
    for candidate in main master; do
        if git show-ref --verify --quiet "refs/heads/$candidate"; then
            branch=$candidate
            break
        fi
    done
fi
if [ -z "$branch" ]; then
    echo "git-checkout-next: cannot determine default branch (no origin/HEAD, no main/master)" >&2
    exit 1
fi

# Walk the default branch's FIRST-PARENT history so `next` follows the
# mainline: a plain `git log` walk interleaves commits merged in from topic
# branches, so after `git prev` onto a mainline commit, `next` could step
# sideways into a merged topic commit instead of the next mainline one.
head=$(git rev-parse HEAD)
next=$(git rev-list --first-parent --reverse "$branch" | awk -v cur="$head" '
    found && !done { print; done = 1 }
    $0 == cur { found = 1 }
')
if [ -z "$next" ]; then
    echo "git-checkout-next: HEAD is not on $branch's first-parent history (or already at its tip)" >&2
    exit 1
fi
git checkout "$next"
