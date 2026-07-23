# Required for gpg sign
export CURRENT_TTY="$TTY"
export GPG_TTY="$CURRENT_TTY"

export EDITOR="nvim"

# Theme for https://github.com/sharkdp/bat
export BAT_THEME="1337"
export BAT_PAGER="ov"

# Pin tealdeer's config dir to ~/.config/tealdeer so the chezmoi-managed
# config.toml is found on all platforms. Default is OS-conventional
# (~/Library/Application Support/tealdeer on macOS).
export TEALDEER_CONFIG_DIR="$HOME/.config/tealdeer"

# Point lazygit at the chezmoi-managed config on all platforms. lazygit's
# only config-dir env var is the generic CONFIG_DIR (too broad to export
# globally), so pin the file directly — its default dir is OS-conventional
# (~/Library/Application Support/lazygit on macOS).
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"

# Increase Claude Code max output tokens (default 32000 is too low)
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000
