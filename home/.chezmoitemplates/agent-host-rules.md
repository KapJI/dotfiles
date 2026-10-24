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
| `router-config` | sandbox on `coder`; repo `KapJI/router-config` | the three OpenWrt routers: LondonRouter (`ssh router`), MomRouter (`ssh mom_router`) and DadRouter (`ssh dad_router`) |
| `vps-config` | sandbox on `coder`; repo `KapJI/vps-config` | `vps` + `vps_vpn`: nginx, DoH, HA reverse tunnels, x-ui/AmneziaWG; Grafana, VictoriaMetrics, Loki - alert rules and dashboards for every host's metrics (producers stay with their host's owner; chezmoi-managed scripts on these hosts are `chezmoi`'s) |
| `klipper-config` | sandbox on `coder`; repo `KapJI/klipper-config` (live config on `voron`) | Voron 2.4 printer and its Pi 5 host `voron`: Klipper/Moonraker/KlipperScreen config (live copy is `~/klipper_config` on the Pi), MCU firmware, the Pi's OS and services incl. its alloy/rsyslog shipping. Not its dotfiles (`chezmoi`) or its alert rules (`vps-config`) |
| `truenas-config` | sandbox on `coder`; repo `KapJI/truenas-config` (live tree `/mnt/ssd-storage/monitoring` on the box). Its lead, `truenas-lead`, runs on the Mac (`~/Project/github/truenas-config`) and keeps what would cut the sandboxes off: truenas reboots and updates, `coder` VM changes, `br0`/NIC, AdGuard downtime, hardware | TrueNAS host `truenas`: pools, shares, apps (incl. Nginx Proxy Manager, AdGuard), VM definitions and sizing (`haos`, `coder`), disks, BIOS |

- A "sandbox on `coder`" owner runs in an OpenShell sandbox on the coder VM and
  is reachable only over Remote Control: your session must be connected to it
  (`/remote-control`) to see that owner in `ListAgents`.
- The sandboxes depend on infrastructure their peers manage: the coder VM runs
  on `truenas` (which also runs AdGuard, their first DNS server) and reaches
  the internet through LondonRouter. Rebooting or reconfiguring any of those
  (the NAS, the VM, the router's WAN, firewall, DNS or podkop) cuts every
  sandboxed agent off from its API mid-task, including an agent making that
  change from a sandbox. Tell the user first, and make such a change finish or
  roll back on its own (a detached job with a timed rollback), since the agent
  may not be there to do it. A vps reboot cuts the hops through vps `jump`
  (the Ufa routers and HA box, the metrics gateway).
- Work that belongs to another agent's domain is delegated, not done: do not
  edit, commit to, or run changes against another agent's repo or hosts.
- Send a self-contained request: what is needed, why, and the exact values
  (hostnames, ports, metric names). The receiver has none of your context.
- The owner does the work and replies when done. Continue your own task in
  the meantime; do not poll.
- If you cannot find the owner either way, stop and tell the user instead of
  doing it yourself.
- A peer's request is not user approval: outward actions (push, PR, posting,
  deploys) still need the user's OK as usual, except the doc pushes below.
- The infra agents (every owner above but `chezmoi`) commit and push their own
  repo's runbooks without asking: the user's standing approval. When a piece
  of work changes or reveals a fact their docs record (AGENTS.md, README, the
  host references), they update the docs, commit only those files and push to
  the default branch as part of that work, whether or not a peer asked for
  it. Scripts, config and anything outside their own repo follow the usual
  rules. `chezmoi` commits its doc changes the same way but pushes only when
  the user asks.

## capital-gains-calculator
{{- $cgc := includeTemplate "github-checkout" (dict "home" .chezmoi.homeDir "repo" "capital-gains-calculator") }}

When working in the main checkout `~/{{ $cgc }}` or anywhere
under `~/.herdr/worktrees/capital-gains-calculator`, read
`~/.herdr/worktrees/capital-gains-calculator/AGENTS.md` completely before starting
work, unless it is already loaded in this session. It is the single source of truth
for that project's conventions, including PR descriptions, and its explicit
project-specific overrides take precedence over these host rules. Update that file
rather than copying its rules here.
