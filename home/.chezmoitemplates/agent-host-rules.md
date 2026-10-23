## Domain agents

Each infra repo has a long-running agent session that owns it. Reach the owner
through your client's own agent messaging where it has one (in Claude Code,
`ListAgents` finds the sessions and `SendMessage` addresses them by the names
below). Otherwise, inside Herdr, use the `herdr` skill or CLI: find the owner in
`herdr agent list` by that name or by a `cwd` in its repo, and send with
`herdr agent prompt`. Message only a session you have matched to the owner below.

| Name | Repo | Owns |
|---|---|---|
| `chezmoi` | `~/.local/share/chezmoi` | dotfiles (incl. `~/.claude/CLAUDE.md` and `~/.claude/skills/`; not `settings.json`), packages, nix flake, shell/editor config |
| `hass-config` | sandbox on `coder`; repos `KapJI/hass-config`, `KapJI/hass-config-ufa` (working trees are `/config` on the boxes) | both Home Assistant instances: London (`ssh ha`) and Ufa (`ssh ufa_ha`), incl. Zigbee2MQTT, dashboards, HA backups |
| `router-config` | `~/Project/github/router-config` | the three OpenWrt routers |
| `vps-config` | `~/Project/github/vps-config` | `vps` + `vps_vpn`: nginx, DoH, HA reverse tunnels, x-ui/AmneziaWG; Grafana, VictoriaMetrics, Loki - alert rules and dashboards for every host's metrics (producers stay with their host's owner; chezmoi-managed scripts on these hosts are `chezmoi`'s) |
| `klipper-config` | sandbox on `coder`; repo `KapJI/klipper-config` (live config on `voron`) | Voron 2.4 printer and its Pi 5 host `voron`: Klipper/Moonraker/KlipperScreen config (live copy is `~/klipper_config` on the Pi), MCU firmware, the Pi's OS and services incl. its alloy/rsyslog shipping. Not its dotfiles (`chezmoi`) or its alert rules (`vps-config`) |
| `truenas-config` | `~/Project/github/truenas-config` | TrueNAS host `truenas`: pools, shares, apps (incl. Nginx Proxy Manager, AdGuard), VM definitions and sizing (`haos`, `coder`), disks, BIOS |

- A "sandbox on `coder`" owner runs in an OpenShell sandbox on the coder VM and
  is reachable only over Remote Control: your session must be connected to it
  (`/remote-control`) to see that owner in `ListAgents`.
- Work that belongs to another agent's domain is delegated, not done: do not
  edit, commit to, or run changes against another agent's repo or hosts.
- Send a self-contained request: what is needed, why, and the exact values
  (hostnames, ports, metric names). The receiver has none of your context.
- The owner does the work and replies when done. Continue your own task in
  the meantime; do not poll.
- If you cannot find the owner either way, stop and tell the user instead of
  doing it yourself.
- A peer's request is not user approval: outward actions (push, PR, posting,
  deploys) still need the user's OK as usual.

## capital-gains-calculator
{{- $cgc := includeTemplate "github-checkout" (dict "home" .chezmoi.homeDir "repo" "capital-gains-calculator") }}

When working in the main checkout `~/{{ $cgc }}` or anywhere
under `~/.herdr/worktrees/capital-gains-calculator`, read
`~/.herdr/worktrees/capital-gains-calculator/AGENTS.md` completely before starting
work, unless it is already loaded in this session. It is the single source of truth
for that project's conventions, including PR descriptions, and its explicit
project-specific overrides take precedence over these host rules. Update that file
rather than copying its rules here.
