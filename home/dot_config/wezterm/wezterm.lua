local wezterm = require 'wezterm'
local config = {}

config.font = wezterm.font_with_fallback {
    {
        family = 'MesloLGS NF',
        harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
    },
    -- Covers Nerd Font glyphs missing from MesloLGS NF (e.g. MDI yaml icon U+E8EB).
    'Symbols Nerd Font Mono',
}
config.line_height = 1.0
if wezterm.target_triple:find("darwin") then
    config.font_size = 14.0
    config.window_decorations = "RESIZE|INTEGRATED_BUTTONS"
else
    config.font_size = 12.0
    config.window_decorations = "TITLE|RESIZE"
end
config.window_padding = {
    left = "0.5cell",
    right = "0.5cell",
    top = "0.5cell",
    bottom = "0.5cell",
}
config.default_cursor_style = 'BlinkingBar'
config.use_fancy_tab_bar = true

config.color_scheme = 'Arthur'

return config
