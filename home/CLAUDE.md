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
- brew: ripgrep          # macOS Homebrew
  deb: ripgrep           # Debian/Ubuntu apt
  winget: BurntSushi.ripgrep  # Windows winget
  scoop: ripgrep         # Windows Scoop
  brew-cask: ...         # macOS GUI apps
  brew-tap: ...          # Homebrew taps
  brew-appstore: ...     # mas (Mac App Store)
  brew-vscode: ...       # VS Code extensions
```

Install scripts in `.chezmoiscripts/` read this YAML and install packages for their platform. When adding a new tool, add it to `packages.yaml` rather than directly to install scripts.

### Templating

Files ending in `.tmpl` are Go templates processed by chezmoi. Template data comes from:
- `.chezmoi.toml.tmpl` — defines `chezmoi.data` (gitEmail, signing keys, etc.)
- Chezmoi built-ins: `{{ .chezmoi.os }}`, `{{ .chezmoi.hostname }}`, etc.

Use `{{ if eq .chezmoi.os "darwin" }}` for OS-specific blocks.

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

The plugin manager is **antidote** (configured in `dot_zsh_plugins.txt`). Plugins are loaded at shell startup.

### Encryption

Sensitive files (SSH keys, age key) are encrypted with `age`. The encrypted key is stored at `.data/key.txt.age`. The unix script `10-decrypt-private-key.sh` decrypts private keys on apply.
