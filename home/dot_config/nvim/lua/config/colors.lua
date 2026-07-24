-- Shared UI colors, single-sourced for config/ui.lua and
-- plugins/lualine.lua. The base comes from the catppuccin palette (with
-- a literal fallback so a missing plugin can't break startup); the two
-- dim variants are custom values that exist only here. The tmux config
-- (dot_tmux.conf.tmpl, window-style) carries the same inactive-pane
-- background — that side can't be derived, keep it in sync by hand.
local ok, palettes = pcall(require, "catppuccin.palettes")
local base = ok and palettes.get_palette("mocha").base or "#1e1e2e"

return {
  active_bg = base, -- catppuccin-mocha base (#1e1e2e)
  inactive_bg = "#24243a", -- Normal bg when the tmux pane is unfocused
  inactive_lualine_bg = "#1e1e31", -- dimmed lualine_c bg (inactive splits / unfocused)
}
