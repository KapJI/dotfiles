---
name: agent-tty
description: Use when driving or verifying interactive terminal apps (neovim, htop, lazygit, fzf, interactive zsh, any TUI) - real PTY sessions with wait primitives, semantic snapshots, and PNG screenshots instead of tmux send-keys + sleep + capture-pane guesswork
---

# agent-tty: driving interactive terminal apps

agent-tty bundles its own always-current skill, kept in sync with the
installed CLI version. Load it first and follow it:

```bash
agent-tty skills get agent-tty
```

`agent-tty skills list` shows other bundled skills (e.g. `dogfood-tui`
for structured TUI QA/dogfooding workflows).

## Machine-specific notes (this dotfiles setup)

- Installed globally via npm into `~/.npm/bin` (the `npm:` key in
  chezmoi's packages.yaml; macOS-only). Non-interactive shells may need
  `export PATH="$HOME/.npm/bin:$PATH"` first.
- Playwright Chromium (screenshots/recordings) is installed by the
  chezmoi macOS npm script; `agent-tty doctor --json` verifies the
  setup.
- Updated weekly by `chezmoi apply` (`npm install -g` fetches latest).

## When NOT to use

- Non-interactive commands: use plain Bash — agent-tty's `run` does not
  capture exit codes or structured output.
- Scripted vim edits: `vim -s script.keys` is deterministic and simpler.
