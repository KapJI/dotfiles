local wezterm = require 'wezterm'
local config = {}

config.font = wezterm.font {
    family = 'MesloLGS NF',
    harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
}
config.font_size = 14.0
config.line_height = 1.0
config.window_decorations = "RESIZE|INTEGRATED_BUTTONS"
config.window_padding = {
    left = "0.5cell",
    right = "0.5cell",
    top = "0.5cell",
    bottom = "0.5cell",
}
config.default_cursor_style = 'BlinkingBar'
config.use_fancy_tab_bar = true

-- Arthur (extracted from iTerm2)
config.color_schemes = {
    ['Arthur'] = {
        foreground = '#DDEEDD',
        background = '#1C1C1C',
        cursor_bg = '#E2BBEF',
        cursor_fg = '#000000',
        cursor_border = '#E2BBEF',
        selection_bg = '#4D4D4D',
        selection_fg = '#FFFFFF',
        ansi = {
            '#3D352A', '#CD5C5C', '#86AF80', '#E8AE5B',
            '#6495ED', '#DEB887', '#B0C4DE', '#BBAA99',
        },
        brights = {
            '#554444', '#CC5533', '#88AA22', '#FFA75D',
            '#87CEEB', '#996600', '#B0C4DE', '#DDCCBB',
        },
    },
}

config.color_scheme = 'Arthur'

return config
