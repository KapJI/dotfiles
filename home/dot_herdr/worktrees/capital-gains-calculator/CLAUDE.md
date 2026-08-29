# capital-gains-calculator — repo conventions

Deliberately outside the repo (never committed). Claude auto-discovers CLAUDE.md in
parent directories, so this covers every worktree beneath it, including ones herdr
creates later.

Host-wide rules — never merge a PR, approval before outward-facing GitHub actions,
no Claude attribution, short ASCII PR bodies, no linter-appeasement rewording — live
in `~/.claude/CLAUDE.md` and are not repeated here. Below is only what is specific to
this repo. Fuller reasoning and the incidents behind each rule are in this project's
memory files.

## PRs

- **Exactly one label per PR**, and it must be a **type-of-change** label:
  `bug`, `feature`, `performance`, `code quality`, `github structure`,
  `documentation`, `testing`, `dependencies`, `removal`. Pick the single best fit —
  do not stack several.
- **Never** add version or release-control labels — `major`, `minor`, `patch`,
  `breaking`, `skip-release`. Those set the release version and are the maintainer's
  call. Never add `automerge` unless asked; it triggers Kodiak.
- The issue-triage labels (`duplicate`, `invalid`, `question`, `wontfix`,
  `good first issue`, `help wanted`) are not PR labels.
- **Kodiak squashes using the branch commit message**, not the PR title. Editing the
  title alone does not change what lands on `main` — amend the commit.
- PR body shape that works here: one or two sentences naming the gap closed, then a
  bullet list of concrete changes (not justifications), then one line for anything
  removed and why that was safe. Cite issues bare: `#620`. The same text is the
  commit body.
- **Dependent PRs are GitHub stacks**: `gh stack link <bottom> <top>`. A plain
  `--base <parent-branch>` child breaks on parent merge in this squash-merge repo.
- **Contributor PRs**: when review finds something to fix, rebase their branch onto
  `main` and push the fix to their fork (`maintainerCanModify` is on), keeping their
  commit intact and adding yours on top. Do not request changes and wait — the repo
  requires up-to-date branches, so PRs go `BEHIND` constantly during review.

## Workflow

- **Describe before implementing.** For each PR in a multi-PR plan, expand it into
  per-change detail (numbered, **Change:**/**Why:**, before/after sketches where
  output changes) and wait for explicit go-ahead before writing code.

## Docs

- **No GitHub issue/PR links in user-facing docs** (`docs/**`, README). Cite issue
  numbers in the PR body or a code comment instead. Links to broker/HMRC pages are
  good — the reader can act on those.
- Non-ASCII is fine in `docs/**`: curly quotes and arrows are house style there. The
  ASCII rule applies to text written to GitHub, not to the documentation files.
- Linter dictionaries live in `.harper-dictionary.txt` and `.harper-ignore.txt`.

## Domain

- **Prove or refuse.** Support only what statute and HMRC guidance establish; where
  they do not, fail with a clear error saying why and what to do instead. A figure
  the user cannot check is worse than no figure, especially if it understates tax.
