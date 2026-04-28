-- UI tweaks that depend on the colorscheme and lualine being loaded.
-- Loaded last in init.lua.

local active_bg = "#1e1e2e"
local inactive_bg = "#24243a"
local inactive_lualine_bg = "#1e1e31"

-- Match tmux active/inactive pane background colors
vim.api.nvim_set_hl(0, "Normal", { bg = active_bg })
vim.api.nvim_set_hl(0, "NormalNC", { bg = inactive_bg })

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
  callback = function()
    vim.api.nvim_set_hl(0, "Normal", { bg = inactive_bg })
    set_lualine_c_bg(inactive_lualine_bg_int)
  end,
})
vim.api.nvim_create_autocmd("FocusGained", {
  callback = function()
    vim.api.nvim_set_hl(0, "Normal", { bg = active_bg })
    set_lualine_c_bg(original_c_bg_int)
  end,
})
