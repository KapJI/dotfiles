-- UI tweaks that depend on the colorscheme and lualine being loaded.
-- Loaded last in init.lua. Overrides re-apply on ColorScheme — a
-- colorscheme (re)load resets every highlight group, which would
-- otherwise wipe them until restart (snacks.lua guards its underline
-- override the same way).

local colors = require("config.colors")
local active_bg = colors.active_bg
local inactive_bg = colors.inactive_bg
local inactive_lualine_bg = colors.inactive_lualine_bg

local augroup = vim.api.nvim_create_augroup("user_ui_overrides", { clear = true })

-- Track terminal focus so the ColorScheme re-apply restores the right
-- variant (an unfocused pane shouldn't pop back to the active bg).
local focused = true

-- Change only the bg of a highlight group, preserving fg and attributes
-- (nvim_set_hl replaces the whole group definition — a bare { bg = ... }
-- would drop catppuccin's Normal fg).
local function set_bg(group, bg)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  hl.bg = bg
  vim.api.nvim_set_hl(0, group, hl)
end

-- Match tmux active/inactive pane background colors
local function apply_normal_bg()
  set_bg("Normal", focused and active_bg or inactive_bg)
  set_bg("NormalNC", inactive_bg)
end

apply_normal_bg()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = augroup,
  callback = apply_normal_bg,
})

-- Dim all nvim windows when tmux pane loses focus.
-- We use the original lualine_c bg (set by the catppuccin-mocha lualine theme)
-- to detect which highlight groups belong to lualine and need dimming.
local ok, lualine_theme = pcall(require, "lualine.themes.catppuccin-mocha")
if not ok then return end

local original_c_bg = lualine_theme.normal.c.bg
local original_c_bg_int = tonumber(original_c_bg:sub(2), 16)
local inactive_lualine_bg_int = tonumber(inactive_lualine_bg:sub(2), 16)

local function set_lualine_c_bg(bg_int)
  for _, group in ipairs(vim.fn.getcompletion("lualine_", "highlight")) do
    if group:match("_inactive") then goto continue end
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    local changed = false
    if hl.bg == original_c_bg_int or hl.bg == inactive_lualine_bg_int then
      hl.bg = bg_int
      changed = true
    end
    if hl.fg == original_c_bg_int or hl.fg == inactive_lualine_bg_int then
      hl.fg = bg_int
      changed = true
    end
    if changed then vim.api.nvim_set_hl(0, group, hl) end
    ::continue::
  end
end

vim.api.nvim_create_autocmd("FocusLost", {
  group = augroup,
  callback = function()
    focused = false
    apply_normal_bg()
    set_lualine_c_bg(inactive_lualine_bg_int)
  end,
})
vim.api.nvim_create_autocmd("FocusGained", {
  group = augroup,
  callback = function()
    focused = true
    apply_normal_bg()
    set_lualine_c_bg(original_c_bg_int)
  end,
})

-- Re-dim lualine after a colorscheme reload while unfocused. Deferred:
-- lualine refreshes its own highlight groups on ColorScheme, and the
-- dim pass must run after that refresh to see the recreated groups.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = augroup,
  callback = function()
    vim.schedule(function()
      if not focused then set_lualine_c_bg(inactive_lualine_bg_int) end
    end)
  end,
})
