# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A cross-platform dotfiles repository managed by [chezmoi](https://www.chezmoi.io/), supporting macOS, Linux (Debian/Ubuntu), and Windows. The source directory (`~/.local/share/chezmoi/home/`) maps to `$HOME` on the target machine.

## Common Commands

```bash
# Apply all dotfiles to the current machine
chezmoi apply

# Pull latest changes and apply
chezmoi update

# Preview what would change (dry run)
chezmoi diff

# Edit a managed file and apply it
chezmoi edit ~/.zshenv
chezmoi apply ~/.zshenv

# Add a new file to be managed
chezmoi add ~/.config/foo/bar.conf

# Re-run a changed script manually
chezmoi apply --force

# Validate templates (useful when editing .tmpl files)
chezmoi execute-template < dot_gitconfig.tmpl
```

Linting is done via pre-commit hooks (installed via `pre-commit`):
```bash
pre-commit run --all-files
```

## Chezmoi File Naming Conventions

Source filenames encode metadata via prefixes/suffixes:

| Source name | Target name | Notes |
|---|---|---|
| `dot_foo` | `.foo` | Hidden file |
| `private_foo` | `foo` | Chmod 600 |
| `readonly_foo` | `foo` | Chmod 444 |
| `executable_foo` | `foo` | Chmod 755 |
| `foo.tmpl` | `foo` | Go template processed |
| `symlink_foo` | `foo` | Symlink; file content is the target path |
| `run_foo.sh` | (script) | Runs on **every** apply |
| `run_once_foo.sh` | (script) | Runs once per unique content hash |
| `run_onchange_foo.sh` | (script) | Runs when rendered content changes |
| `run_[once_/onchange_]before_foo.sh` | (script) | `before_` runs before files are applied |
| `run_[once_/onchange_]after_foo.sh` | (script) | `after_` runs after files are applied |

## Architecture

### Package Management

All packages are defined in a single central manifest: `.data/packages.yaml`. Each entry can have keys for multiple platforms:

```yaml
- nix: ripgrep           # Nix (macOS arm64 + Linux x86_64/aarch64; cross-platform CLI tools)
  nix-desktop: ...       # Nix, included only when is_desktop=true
  nix-server: ...        # Nix, included only when is_desktop=false (Linux server)
  llm-agents: omp        # numtide/llm-agents.nix flake (AI coding agents)
  brew-cask: ...         # macOS GUI apps
  brew-tap: ...          # Homebrew taps
  brew-appstore: ...     # mas (Mac App Store)
  brew-vscode: ...       # VS Code extensions
  brew: colima           # macOS-only formulae (rare; CLI tools should use nix:)
  deb: ...               # Debian/Ubuntu apt (system libraries / OS-integration only)
  deb-desktop: ...       # Debian/Ubuntu apt (Linux desktop only — GUI apps)
  deb-server: ...        # Debian/Ubuntu apt (Linux server only)
  snap-desktop: ...      # Snap (Linux desktop only) - for apps not in apt
  winget: BurntSushi.ripgrep  # Windows winget
  scoop: ripgrep         # Windows Scoop
  uv-tool: ...           # Python tools via uv (Windows; Unix uses nix:)
  ps-module: ...         # PowerShell modules from PSGallery (Windows)
  npm: agent-tty         # npm globals into the ~/.npm prefix (desktop + container)
  claude-plugin: ...     # Claude Code plugin, "<plugin>@<marketplace>"
  codex-plugin: ...      # Codex plugin, "<plugin>@<marketplace>"
  omp-plugin: ...        # omp (Pi harness) plugin: npm spec or git: ref
  agent-marketplace: ... # marketplace source added before the two above install
```

Default routing:
- **CLI tools** → `nix:` (covers macOS + Linux). Pinned via committed `flake.lock` for cross-host reproducibility.
- **macOS GUI apps** → `brew-cask:`. Mac App Store apps → `brew-appstore:`.
- **Linux GUI apps / system libraries** → `deb:` / `deb-desktop:` (apt is intentionally retained for these).
- **Windows** → `winget:` (preferred) / `scoop:` (fallback).
- **AI coding agents** → `llm-agents:` — the `numtide/llm-agents.nix` flake, rebuilt daily and
  prebuilt in `cache.numtide.com`. Prefer it over `nix:` for agents: nixpkgs lags upstream badly
  and some (`omp`) aren't packaged there at all.
- **npm-only tools** (no nix/brew packaging) → `npm:` — installed by `unix/run_onchange_after_75-install-npm-packages.sh.tmpl` into the `~/.npm` prefix (the nix node's own global prefix is a read-only store path). `.chezmoiignore` gates the script, and `.claude/skills/agent-tty` with it, to desktop + container: headless servers have no TUI to drive.
- **AI agent plugins** → `claude-plugin:` / `codex-plugin:` / `omp-plugin:` / `agent-marketplace:` — installed by `unix/run_onchange_after_76-install-agent-plugins.sh.tmpl` for whichever agents the host has. One entry per logical plugin; the per-agent keys are install methods for the *same* plugin, exactly as `brew-cask`/`deb`/`winget` are for an OS package. Claude and Codex take `<plugin>@<marketplace>` and need `agent-marketplace:` (the source added first); omp has no marketplace and takes an npm spec or `git:` ref, which needs **`nix: bun`** — `omp install` shells out to bun and fails without it. Every step in the script is non-fatal: a registry being down must never fail an apply.

**Coder/CI containers ignore `.chezmoiscripts/**` wholesale** (last block of `.chezmoiignore`, placed last so it wins). A new script that must run in a workspace needs its own `!.chezmoiscripts/<dir>/<name>.sh` re-include there, keyed on the *target* name — no `run_onchange_after_` prefix. Three are re-included today: the nix-profile sync, npm packages, and agent plugins.

Install scripts in `.chezmoiscripts/` read this YAML and install packages for their platform. When adding a new CLI tool, prefer `nix:` and skip `brew:` / `deb:` unless you have a reason (system lib, GUI integration).

**One entry per logical package.** Multiple keys on the same `- ` entry are for cross-platform install methods of the *same* package (e.g. `brew-cask: 1password` + `deb-desktop: 1password` + `winget: AgileBits.1Password`). Distinct packages — even if functionally related (e.g. `tmux` and `tmuxPlugins.fingers`) — get separate top-level entries.

#### Nix flake

A flake at `~/.config/nix-profile/flake.nix` is rendered inline by `home/.chezmoiscripts/unix/run_onchange_before_03-nix-profile-sync.sh.tmpl` from the `nix:` / `nix-desktop:` / `nix-server:` / `llm-agents:` keys. It has two flake inputs:
- `nixpkgs` (nixos-unstable channel) — most CLI tools.
- `llm-agents` (`github:numtide/llm-agents.nix`) — AI coding agents (`claude-code`, `codex`, `omp`), rebuilt daily and published prebuilt to `cache.numtide.com`, so they track upstream far faster than nixpkgs. The `llm-agents` input deliberately omits `inputs.nixpkgs.follows`: overriding it changes every derivation hash and misses that cache, which for `omp` means a local ~16 min Rust build on every host. `unix/02-nix-substituters` adds the cache to `/etc/nix/nix.custom.conf` (root-owned, because nix ignores substituters from untrusted users).

`flake.lock` is chezmoi-managed at `home/dot_config/nix-profile/flake.lock` for cross-host reproducibility. The before_03 script reads it from `chezmoi sourceDir` directly (because chezmoi target-state writes happen *after* `before_*` scripts) and chezmoi's later target-write phase is a no-op when content matches.

Bump versions on a primary host with `bump-locks` (see Zsh Configuration — it bumps the flake **and** the antidote plugin pins in one shot):
```bash
bump-locks           # nix flake update + plugin pins + chezmoi re-add + commit
chezmoi cd && git show   # review the "deps: bump flake.lock + plugin pins" commit
git push
```
`bump-locks` commits the two re-added files itself (by source path, so unrelated
working-tree edits stay out of it) but never pushes; it skips the commit
entirely if any pin lookup failed, leaving the bump in the working tree.
Other hosts: `chezmoi update` → before_03 reruns (lock hash changed) → `nix profile remove` + `nix profile add` rebuilds the profile entry atomically.

**Boot race (macOS).** `/nix` is an encrypted APFS volume mounted by `determinate-nixd init` from a `RunAtLoad` LaunchDaemon with no ordering against login items, and `/etc/zshrc`'s nix hook is guarded by `[ -e .../nix-daemon.sh ]`. A terminal restored at login can start its first shell *before* the mount, and that shell then silently has no nix at all — no nix on `$PATH`, no `NIX_PROFILES`, no `z`/`zi`, no fzf widgets, no nix-tool completions, and `git` resolving to `/usr/bin/git` — while `.zshrc` still runs to completion, so it looks normal. `config.d/nix_heal.zsh` arms a `precmd` hook in exactly that case and redoes the missing work once the volume appears. It is not dead code; don't drop it because a healthy shell never runs it. Note this is why `path.zsh` uses `typeset -gU path`: it is re-sourced from inside that hook, and a bare `typeset` would make `path` local and throw the repair away.

Scripts that invoke nix-installed tools (`uv`, `nvim`, etc.) source `/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh` at the top so the nix profile is on PATH (chezmoi runs each script in a fresh non-interactive shell).

### Templating

Files ending in `.tmpl` are Go templates processed by chezmoi. Template data comes from:
- `.chezmoi.toml.tmpl` — defines `chezmoi.data` (gitEmail, signing keys, `is_desktop`, etc.)
- Chezmoi built-ins: `{{ .chezmoi.os }}`, `{{ .chezmoi.hostname }}`, etc.

Use `{{ if eq .chezmoi.os "darwin" }}` for OS-specific blocks. Use `{{ if .is_desktop }}` to gate desktop-only behavior — `.is_desktop` is `true` on macOS and Windows; on Linux it is prompted at first init via `promptBoolOnce` (default `false` for backward-compat with existing servers).

### OS-Specific Scripts

`.chezmoiscripts/` is organized by OS:
- `linux/` — Debian-specific install scripts
- `macos/` — macOS-specific install scripts
- `unix/` — Shared Unix scripts (run on both macOS and Linux)
- `windows/` — PowerShell scripts

`.chezmoiignore` conditionally excludes directories based on `{{ .chezmoi.os }}`, so only relevant scripts run on each platform.

### External Dependencies

`.chezmoiexternal.toml` declares external files/archives to download (eza/yazi themes, fonts, binary completions, the tree-sitter CLI, git repos like antidote, tag-pinned tmux plugins). These are fetched automatically during `chezmoi apply`.

### Zsh Configuration

The zsh config is modular under `dot_config/zsh/config.d/`:
- `aliases.zsh` — shell aliases
- `path.zsh` — PATH modifications
- `env.zsh.tmpl` — environment variables (templated)
- `key_bindings.zsh` — keybindings

The plugin manager is **antidote** (configured in `dot_config/zsh/dot_zsh_plugins.txt`). Plugins are loaded at shell startup via a static bundle (`config.d/antidote.zsh`).

Every plugin is **pinned to a commit SHA** (`pin:<sha>` in `dot_zsh_plugins.txt`) for cross-host reproducibility, mirroring `flake.lock` and the tag-pinned tmux plugins. antidote itself is pinned too (an archive at a SHA in `.chezmoiexternal.toml`, which also disables its self-update). `antidote update` (weekly, `run_onchange_after_80`) skips pinned bundles, so shells don't roll forward on their own. Bump deliberately with `bump-locks` (also bumps the nix flake):

```bash
bump-locks         # rewrites every pin: to upstream HEAD + nix flake, re-adds, commits
# then review and push:
chezmoi cd && git show
```

To bump one plugin, edit its SHA by hand and `chezmoi apply`. `ohmyzsh` spans several lines but is one clone — all its lines must share the same SHA (antidote errors on a pin conflict within a bundle). antidote itself bumps by editing the SHA in `.chezmoiexternal.toml`.

### Neovim plugins

`lazy-lock.json` is **not** chezmoi-managed, unlike `flake.lock` and the antidote pins. lazy.nvim rewrites it on every `:Lazy update` / `:Lazy sync`, so tracking it meant re-adding a machine-generated file by hand forever. Each host keeps its own lock, and `:Lazy restore` still rolls that host back to it.

Plugins roll forward on their own: `unix/run_onchange_after_90-install-vim-plugins.sh.tmpl` runs `Lazy! sync` (install + update + clean) weekly. The trade is deliberate — no cross-host pinning, and a bad upstream update arrives unannounced. Undo one with `:Lazy restore`, or pin that plugin's `commit`/`version` in its spec under `lua/plugins/`.

### Encryption

Sensitive files (SSH keys, age key) are encrypted with `age`. The encrypted key is stored at `.data/key.txt.age`. The unix script `10-decrypt-private-key.sh` decrypts private keys on apply.
