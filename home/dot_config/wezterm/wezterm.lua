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

-- ── Tab bar styling ──────────────────────────────────────────────────────
-- iTerm2 model: active tab BLENDS with window content bg, inactive is
-- DARKER (recedes into titlebar), hover is BRIGHTER (lifts off). Colors
-- are derived from the active color_scheme's background so they track
-- automatically if the scheme changes.
local scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
local window_bg = scheme.background
local bg = wezterm.color.parse(window_bg)

local titlebar_bg  = bg:darken(0.30)   -- a touch darker than window
local inactive_bg  = bg:darken(0.50)   -- noticeably recessed
local hover_bg     = bg:lighten(0.08)  -- subtly raised above window bg

config.window_frame = {
    font_size = wezterm.target_triple:find('darwin') and 15.0 or 13.0,
    active_titlebar_bg   = titlebar_bg,
    inactive_titlebar_bg = titlebar_bg,
}

config.colors = {
    tab_bar = {
        active_tab = {
            bg_color  = window_bg,            -- blends with content area
            fg_color  = '#ffffff',
            intensity = 'Bold',
        },
        inactive_tab = {
            bg_color = inactive_bg,           -- recedes into the bar
            fg_color = '#9a9a9a',
        },
        inactive_tab_hover = {
            bg_color = hover_bg,              -- lifts off when hovered
            fg_color = '#ffffff',
        },
        inactive_tab_edge = '#575757',
    },
}

-- ── smart-splits.nvim / tmux passthrough ─────────────────────────────────
-- Alt+hjkl       → navigate panes (forward to nvim or tmux if either is the
--                   foreground process; otherwise wezterm handles it)
-- Alt+Shift+HJKL → resize panes (3 cells per press, same forwarding)
--
-- Forwarding chain when nested (e.g. wezterm split → tmux → nvim):
--   wezterm sees tmux as foreground → forwards M-h to tmux
--   tmux's is_vim shell check sees nvim → forwards M-h to nvim
--   nvim's smart-splits handles the key; on edge, sends back through tmux
--   tmux passes to wezterm via the same chain
--
-- Detection:
--   - IS_NVIM user-var (set by smart-splits via OSC) — works through SSH/et
--   - IS_TMUX user-var (set by tmux client-attached hook via OSC) — same
--   - foreground process name == "tmux" / "nvim" — local case (no OSC)
--
-- Transport processes (ssh, et, mosh-client) are NOT checked: when SSH'd to
-- a bare remote shell, M-h should still navigate wezterm panes locally.
-- When SSH'd to remote tmux, the IS_TMUX user-var emitted by tmux's
-- client-attached hook reaches us through the transport's OSC passthrough.
local function is_inner_app(pane)
    local uv = pane:get_user_vars()
    if uv.IS_NVIM == 'true' or uv.IS_TMUX == 'true' then return true end
    local proc = (pane:get_foreground_process_name() or ''):gsub('^.*/', '')
    return proc == 'tmux' or proc == 'nvim'
end

local direction_keys = { h = 'Left', j = 'Down', k = 'Up', l = 'Right' }

local function split_nav(action, key)
    local mods = (action == 'resize') and 'ALT|SHIFT' or 'ALT'
    return {
        key = key,
        mods = mods,
        action = wezterm.action_callback(function(win, pane)
            if is_inner_app(pane) then
                -- Forward to the inner app (tmux or nvim); they handle routing.
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
