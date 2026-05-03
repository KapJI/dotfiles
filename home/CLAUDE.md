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
| `run_foo.sh` | (runs once) | Script run on apply |
| `run_onchange_foo.sh` | (runs on change) | Script run when content changes |
| `before_foo.sh` | (before apply) | Script run before applying |
| `after_foo.sh` | (after apply) | Script run after applying |

## Architecture

### Package Management

All packages are defined in a single central manifest: `.data/packages.yaml`. Each entry can have keys for multiple platforms:

```yaml
- nix: ripgrep           # Nix (macOS arm64 + Linux x86_64/aarch64; cross-platform CLI tools)
  nix-desktop: ...       # Nix, included only when is_desktop=true
  nix-server: ...        # Nix, included only when is_desktop=false (Linux server)
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
  uv-tool: ...           # Python tools via uv (all platforms)
```

Default routing:
- **CLI tools** → `nix:` (covers macOS + Linux). Pinned via committed `flake.lock` for cross-host reproducibility.
- **macOS GUI apps** → `brew-cask:`. Mac App Store apps → `brew-appstore:`.
- **Linux GUI apps / system libraries** → `deb:` / `deb-desktop:` (apt is intentionally retained for these).
- **Windows** → `winget:` (preferred) / `scoop:` (fallback).

Install scripts in `.chezmoiscripts/` read this YAML and install packages for their platform. When adding a new CLI tool, prefer `nix:` and skip `brew:` / `deb:` unless you have a reason (system lib, GUI integration).

**One entry per logical package.** Multiple keys on the same `- ` entry are for cross-platform install methods of the *same* package (e.g. `brew-cask: 1password` + `deb-desktop: 1password` + `winget: AgileBits.1Password`). Distinct packages — even if functionally related (e.g. `tmux` and `tmuxPlugins.fingers`) — get separate top-level entries.

#### Nix flake

A flake at `~/.config/nix-profile/flake.nix` is rendered inline by `home/.chezmoiscripts/unix/run_onchange_before_03-nix-profile-sync.sh.tmpl` from the `nix:` / `nix-desktop:` / `nix-server:` keys. It has two flake inputs:
- `nixpkgs` (nixos-unstable channel) — most CLI tools.
- `claude-code-nix` (`github:sadjow/claude-code-nix`) — daily-fresh `claude-code`, decoupled from nixpkgs cadence so it gets bumped within hours of upstream releases.

`flake.lock` is chezmoi-managed at `home/dot_config/nix-profile/flake.lock` for cross-host reproducibility. The before_03 script reads it from `chezmoi sourceDir` directly (because chezmoi target-state writes happen *after* `before_*` scripts) and chezmoi's later target-write phase is a no-op when content matches.

Bump versions on a primary host:
```bash
nix-bump-lock        # alias: nix flake update + chezmoi re-add flake.lock
chezmoi cd && git diff home/dot_config/nix-profile/flake.lock
git commit -am "nix: bump flake.lock"
git push
```
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

`.chezmoiexternal.toml` declares external files/archives to download (vim-plug, eza themes, binary completions, git repos like antidote and tpm). These are fetched automatically during `chezmoi apply`.

### Zsh Configuration

The zsh config is modular under `dot_config/zsh/config.d/`:
- `aliases.zsh` — shell aliases
- `path.zsh` — PATH modifications
- `env.zsh.tmpl` — environment variables (templated)
- `key_bindings.zsh` — keybindings

The plugin manager is **antidote** (configured in `dot_config/zsh/dot_zsh_plugins.txt`). Plugins are loaded at shell startup.

### Encryption

Sensitive files (SSH keys, age key) are encrypted with `age`. The encrypted key is stored at `.data/key.txt.age`. The unix script `10-decrypt-private-key.sh` decrypts private keys on apply.
