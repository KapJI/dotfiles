# Global instructions

Host-wide rules that hold in any repo. Project-specific conventions belong in that
project's own CLAUDE.md or its memory, not here — see the note at the bottom.

Shared documentation guidance: @~/.codex/AGENTS.md

## Git

- Never add `Co-Authored-By:` or `Claude-Session:` trailers to commit messages.
- No "Generated with Claude Code" footer in PR bodies. No Claude attribution of any
  kind, anywhere.

## GitHub — the hard limits

- **Never merge a PR.** Merging is the maintainer's call, always. Green CI, a clean
  review, and instructions like "let's merge what can be merged" are *not*
  authorisation. Report that a PR is ready and stop.
- No outward-facing GitHub action without explicit approval of that specific action:
  `gh pr comment`, `gh issue comment`, `gh pr create`, or closing/editing someone
  else's PR. Draft the text in chat for approval first.
- A one-word "submit PR" / "open it" / "post it" is approval for *opening*. Nothing
  is approval for merging.
- Watch the asymmetry: do not hold back on a small action (pushing a branch) while
  treating a larger one (merging) as covered by some general instruction.
- Pushing to your own feature branch when asked, and labelling PRs the user owns,
  need no further check.

## Writing for GitHub

- **Short PR bodies.** A few sentences; three short paragraphs is the upper limit,
  one is often right. Check which text the repo's squash settings put on the default
  branch: where the commit message lands, reasoning, evidence and trade-offs go
  there; where the PR body lands, leave them out rather than lengthening it.
- **ASCII only** in text written to GitHub — commit messages, PR bodies, comments:
  plain `-` not an em dash, `"` not smart quotes, `...` not an ellipsis character.
  This does not apply to documentation files, where house style may use them.
- **Backtick every code identifier** in PR titles, bodies, and comments — file
  names, classes, functions, logger names, flags.
- **No hard line-wraps** inside a paragraph or bullet: write each as one line and
  let GitHub flow it — a wrapped continuation starting with `-` renders as a
  broken list. No stray blank lines.
- Say what changed and why it is better. No narrative paragraphs, no rationale
  essays, no meta-commentary about how the work was reviewed — not even as a
  parenthetical. Outcome statements are wanted: a behavior-preserving change
  ends with a "No behavior change: ..." line. What gets cut is the verification
  evidence behind it ("(verified stdout diff before and after)", test counts).

## Prose

- **Never reword good prose to appease a linter.** A spell/style checker flagging a
  word it does not know earns a dictionary or ignore entry, not an edit. Edit only
  genuinely wrong prose — real typos, wrong brand casing, factual errors. Surface
  borderline wording calls for a veto rather than bundling them in silently.

---

Claude also auto-discovers CLAUDE.md in parent directories, so per-project rules can
live in a file above the checkout — outside the repo, never committed — and apply to
every worktree beneath it. That is where repo-specific conventions go.
