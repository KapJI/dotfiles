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

-- ── smart-splits.nvim integration ────────────────────────────────────────
-- Alt+hjkl   → navigate panes (forward to nvim if it's the active pane)
-- Alt+Shift+HJKL → resize panes (3 cells per press, same forwarding)
-- nvim sets the user-var IS_NVIM=true via smart-splits, which we read here.
local function is_vim(pane)
    return pane:get_user_vars().IS_NVIM == 'true'
end

local direction_keys = { h = 'Left', j = 'Down', k = 'Up', l = 'Right' }

local function split_nav(action, key)
    local mods = (action == 'resize') and 'ALT|SHIFT' or 'ALT'
    return {
        key = key,
        mods = mods,
        action = wezterm.action_callback(function(win, pane)
            if is_vim(pane) then
                -- Forward the keystroke to nvim; smart-splits handles it.
                win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
            elseif action == 'resize' then
                win:perform_action(
                    { AdjustPaneSize = { direction_keys[key], 3 } },
                    pane
                )
            else
                win:perform_action(
                    { ActivatePaneDirection = direction_keys[key] },
                    pane
                )
            end
        end),
    }
end

config.keys = {
    split_nav('move',   'h'),
    split_nav('move',   'j'),
    split_nav('move',   'k'),
    split_nav('move',   'l'),
    split_nav('resize', 'h'),
    split_nav('resize', 'j'),
    split_nav('resize', 'k'),
    split_nav('resize', 'l'),
}

return config
