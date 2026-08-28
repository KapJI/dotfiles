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
  npm: agent-tty         # npm globals into the ~/.npm prefix (macOS-only for now)
```

Default routing:
- **CLI tools** → `nix:` (covers macOS + Linux). Pinned via committed `flake.lock` for cross-host reproducibility.
- **macOS GUI apps** → `brew-cask:`. Mac App Store apps → `brew-appstore:`.
- **Linux GUI apps / system libraries** → `deb:` / `deb-desktop:` (apt is intentionally retained for these).
- **Windows** → `winget:` (preferred) / `scoop:` (fallback).
- **AI coding agents** → `llm-agents:` — the `numtide/llm-agents.nix` flake, rebuilt daily and
  prebuilt in `cache.numtide.com`. Prefer it over `nix:` for agents: nixpkgs lags upstream badly
  and some (`omp`) aren't packaged there at all.
- **npm-only tools** (no nix/brew packaging) → `npm:` — installed by `macos/run_onchange_after_75-install-npm-packages.sh.tmpl` (macOS-only for now; add a Linux consumer when needed).

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

### Neovim plugin lockfile

`home/dot_config/nvim/lazy-lock.json` pins every lazy.nvim plugin to a commit for cross-host reproducibility — it is the source of truth a fresh `chezmoi apply` restores from. lazy.nvim writes the *deployed* copy (`~/.config/nvim/lazy-lock.json`) whenever you `:Lazy update` / `:Lazy sync` in the editor, which is a chezmoi target — so the two **drift** until you push the change back:

```bash
chezmoi re-add ~/.config/nvim/lazy-lock.json   # after any in-editor :Lazy update/sync
chezmoi cd && git diff home/dot_config/nvim/lazy-lock.json
```

Skip this and a fresh install (or `:Lazy restore` on another host) rolls the drifted plugins *backward* to the stale source commits — the opposite of what you want. `chezmoi diff` surfaces the drift if you forget.

### Encryption

Sensitive files (SSH keys, age key) are encrypted with `age`. The encrypted key is stored at `.data/key.txt.age`. The unix script `10-decrypt-private-key.sh` decrypts private keys on apply.
