#!/bin/bash
# Check out the child of HEAD on the default branch's history — the
# counterpart of `git prev` (checkout HEAD^). Used by the `git next`
# alias in .gitconfig.
set -eu

# Default branch: origin/HEAD when set, else a local main/master.
branch=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || true)
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

next=$(git log --reverse --pretty=%H "$branch" | awk -v cur="$(git rev-parse HEAD)" '
    found && !done { print; done = 1 }
    $0 == cur { found = 1 }
')
if [ -z "$next" ]; then
    echo "git-checkout-next: HEAD is not an ancestor of $branch (or already at its tip)" >&2
    exit 1
fi
git checkout "$next"
