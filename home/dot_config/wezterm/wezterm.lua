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
config.window_padding       = {
    left = "0.5cell",
    right = "0.5cell",
    top = "0.5cell",
    bottom = "0.5cell",
}
config.default_cursor_style = 'BlinkingBar'
config.use_fancy_tab_bar    = true

-- Cap to 120fps (ProMotion ceiling); vsync caps lower on 60/90Hz
-- displays automatically, so this is safe on any monitor. Default is
-- 60 for max_fps and 10 for animation_fps — the latter makes cursor
-- blink and scroll feel sluggish on high-refresh panels.
config.max_fps              = 120
config.animation_fps        = 120

config.color_scheme         = 'Arthur'

-- ── Tab bar styling ──────────────────────────────────────────────────────
-- iTerm2 model: active tab BLENDS with window content bg, inactive is
-- DARKER (recedes into titlebar), hover is BRIGHTER (lifts off). Colors
-- are derived from the active color_scheme's background so they track
-- automatically if the scheme changes.
local scheme                = wezterm.color.get_builtin_schemes()[config.color_scheme]
local window_bg             = scheme.background
local bg                    = wezterm.color.parse(window_bg)

local titlebar_bg           = bg:darken(0.30)  -- a touch darker than window
local inactive_bg           = bg:darken(0.50)  -- noticeably recessed
local hover_bg              = bg:lighten(0.08) -- subtly raised above window bg

config.window_frame         = {
    font_size            = wezterm.target_triple:find('darwin') and 16.0 or 14.0,
    active_titlebar_bg   = titlebar_bg,
    inactive_titlebar_bg = titlebar_bg,
}

config.colors               = {
    tab_bar = {
        active_tab = {
            bg_color  = window_bg, -- blends with content area
            fg_color  = '#ffffff',
            intensity = 'Bold',
        },
        inactive_tab = {
            bg_color = inactive_bg, -- recedes into the bar
            fg_color = '#9a9a9a',
        },
        inactive_tab_hover = {
            bg_color = hover_bg, -- lifts off when hovered
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
--   nvim's smart-splits moves within nvim, or at its edge hands off to
--     tmux's own select-pane
--
-- The key does NOT climb back out to wezterm: tmux's select-pane wraps
-- (leftmost↔rightmost) instead of hitting an edge, and while IS_TMUX is set
-- wezterm forwards M-hjkl unconditionally — a key handed back would just
-- bounce straight in again. So wezterm-level panes respond to Alt-hjkl only
-- when the foreground app is neither tmux nor nvim.
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

-- ── Alt-Y: copy the previous command's output ────────────────────────────
-- At a bare wezterm prompt (no tmux) copy the last command's output to the
-- clipboard. This uses OSC 133 *semantic zones* — the iterm2 shell-integration
-- plugin (zsh/config.d/plugins/…) emits 133;A/B/C/D marking prompt and output
-- boundaries, and wezterm records them as zones. Grabbing the last "Output"
-- zone is exact: no ❯-glyph guessing and no scrollback-line cap, so output
-- that itself contains a ❯ can't mis-anchor the selection — the failure mode
-- of the old `wezterm cli get-text` zsh widget this replaces.
--
-- Inside tmux/nvim, forward Alt-Y to the inner app exactly like the M-hjkl
-- keys above (same is_inner_app test): tmux's own `bind -n M-Y` does the
-- equivalent copy from the marks it records, so this must not intercept it
-- there. Key is Alt+Shift+y (capital Y), matching tmux's M-Y and the old
-- widget's `^[Y`; forwarding re-encodes it as ESC-Y, which is what tmux reads.
local function copy_last_output(win, pane)
    if is_inner_app(pane) then
        win:perform_action({ SendKey = { key = 'y', mods = 'ALT|SHIFT' } }, pane)
        return
    end
    local zones = pane:get_semantic_zones('Output')
    if #zones == 0 then
        return
    end
    local text = pane:get_text_from_semantic_zone(zones[#zones])
    -- Trim trailing whitespace/blank lines (the p10k prompt-gap newline and
    -- anything the command left dangling) so the clipboard ends at the last
    -- real line of output.
    text = (text or ''):gsub('%s+$', '')
    if text == '' then
        return
    end
    win:copy_to_clipboard(text)
end

config.keys = {
    split_nav('move', 'h'),
    split_nav('move', 'j'),
    split_nav('move', 'k'),
    split_nav('move', 'l'),
    split_nav('resize', 'h'),
    split_nav('resize', 'j'),
    split_nav('resize', 'k'),
    split_nav('resize', 'l'),
    { key = 'y', mods = 'ALT|SHIFT', action = wezterm.action_callback(copy_last_output) },
}

return config
