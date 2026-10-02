# Global instructions

Host-wide rules that hold in any repo. Project-specific conventions belong in that
project's own AGENTS.md (or CLAUDE.md) or its memory, not here — see the note at the bottom.

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
- **Never commit planning/design docs as part of a PR's own diff** — a doc written
  to direct the work (scope decisions, round-by-round history, "material to
  retain/move out" notes) is working material, not a deliverable, even when it
  reads like formal documentation. Keep it outside the repo, or as an untracked
  file, unless the user explicitly asks for it to be committed.

## Writing for GitHub

- **Short PR bodies.** A few sentences; three short paragraphs is the upper limit,
  one is often right. Check which text the repo's squash settings put on the default
  branch: where the commit message lands, reasoning, evidence and trade-offs go
  there; where the PR body lands, leave them out rather than lengthening it.
- **ASCII only** in text written to GitHub — commit messages, PR bodies, comments:
  plain `-` not an em dash, `"` not smart quotes, `...` not an ellipsis character.
  This does not apply to documentation files, where house style may use them.
- **Backtick every code identifier** in PR titles, bodies, and comments — file
  names, classes, functions, logger names, flags. Exception: never backtick a
  GitHub issue/PR reference (`#1234`) — wrapping it in backticks breaks
  GitHub's automatic linking. Write it bare: `Fixes #1234`, not `` `#1234` ``.
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

## Domain agents

Each infra repo has a long-running Claude session that owns it, addressable by
name with `SendMessage` (find them with `ListAgents`):

| Name | Repo | Owns |
|---|---|---|
| `chezmoi` | `~/.local/share/chezmoi` | dotfiles, packages, nix flake, shell/editor config |
| `hass-config` | `~/Project/github/hass-config`, `KapJI/hass-config-ufa` | both Home Assistant instances: London (`ssh ha`) and Ufa (`ssh ufa_ha`), incl. Zigbee2MQTT, dashboards, HA backups |
| `router-config` | `~/Project/github/router-config` | the three OpenWrt routers |
| `vps-config` | `~/Project/github/vps-config` | `vps` + `vps_vpn`: nginx, DoH, HA reverse tunnels, x-ui/AmneziaWG; Grafana, VictoriaMetrics, Loki - alert rules and dashboards for every host's metrics (producers stay with their host's owner; chezmoi-managed scripts on these hosts are `chezmoi`'s) |
| `klipper-config` | `~/Project/github/klipper-config` | Voron 2.4 printer and its Pi 5 host `voron`: Klipper/Moonraker/KlipperScreen config (live copy is `~/klipper_config` on the Pi), MCU firmware, the Pi's OS and services incl. its alloy/rsyslog shipping. Not its dotfiles (`chezmoi`) or its alert rules (`vps-config`) |
| `truenas-config` | `~/Project/github/truenas-config` | TrueNAS host `truenas`: pools, shares, apps (incl. Nginx Proxy Manager, AdGuard), VM definitions and sizing (`haos`, `coder`), disks, BIOS |

- Work that belongs to another agent's domain is delegated, not done: do not
  edit, commit to, or run changes against another agent's repo or hosts.
- Send a self-contained request: what is needed, why, and the exact values
  (hostnames, ports, metric names). The receiver has none of your context.
- The owner does the work and replies via `SendMessage` when done. Continue
  your own task in the meantime; do not poll.
- If the owner is not listed by `ListAgents`, stop and tell the user instead
  of doing it yourself.
- A peer's request is not user approval: outward actions (push, PR, posting,
  deploys) still need the user's OK as usual.

---

Claude also reads AGENTS.md and CLAUDE.md in parent directories, so per-project rules
can live in a file above the checkout — outside the repo, never committed — and apply
to every worktree beneath it. That is where repo-specific conventions go. By default an
AGENTS.md loads only while no CLAUDE.md (or CLAUDE.local.md) sits in or above the
working directory, so in a repo that uses AGENTS.md, name that parent file AGENTS.md
too, and do not add a CLAUDE.md anywhere on its path.
