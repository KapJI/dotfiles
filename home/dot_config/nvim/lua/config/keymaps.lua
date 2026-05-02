-- Global, plugin-independent keymaps. Plugin-specific keymaps live alongside
-- their plugin spec or in LspAttach (config/lsp.lua).

local keyset = vim.keymap.set

-- Toggle verbose listchars
local full_listchars    = { eol = "¬", tab = ">·", trail = "~", extends = ">", precedes = "<", space = "␣" }
local minimal_listchars = { extends = ">", precedes = "<", tab = "  ", trail = "~" }
keyset("n", "<C-l>", function()
  if vim.opt.listchars:get().eol then
    vim.opt.listchars = minimal_listchars
  else
    vim.opt.listchars = full_listchars
  end
end, { desc = "Toggle verbose listchars" })

-- Clipboard (OSC52)
keyset({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
keyset("n", "<leader>p", '"+p', { desc = "Paste from clipboard" })

-- Toggle comments
keyset("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment" })
keyset("v", "<leader>/", "gc", { remap = true, desc = "Toggle comment" })

-- Clear search highlight
keyset("n", "<leader>h", ":nohlsearch<CR>", { silent = true, desc = "Clear search highlight" })

-- "inside line" text object (excludes leading/trailing whitespace)
keyset({ "x", "o" }, "il", ":<C-u>normal! ^vg_<CR>", { silent = true, desc = "Inside line" })

-- Arrow keys disabled by default; toggle with :Arrows on/off
local _arrow_keys = { "<Up>", "<Down>", "<Left>", "<Right>" }
local _arrow_modes = { "n", "v" }
local function disable_arrows()
  for _, key in ipairs(_arrow_keys) do
    for _, mode in ipairs(_arrow_modes) do
      keyset(mode, key, "<Nop>", { desc = "Use hjkl (or :Arrows on)" })
    end
  end
end
local function enable_arrows()
  for _, key in ipairs(_arrow_keys) do
    for _, mode in ipairs(_arrow_modes) do
      pcall(vim.keymap.del, mode, key)
    end
  end
end
disable_arrows()
vim.api.nvim_create_user_command("Arrows", function(opts)
  if opts.args == "on" then
    enable_arrows()
    vim.notify("Arrow keys enabled", vim.log.levels.INFO)
  elseif opts.args == "off" then
    disable_arrows()
    vim.notify("Arrow keys disabled", vim.log.levels.INFO)
  else
    vim.notify("Usage: :Arrows on|off", vim.log.levels.WARN)
  end
end, { nargs = 1, complete = function() return { "on", "off" } end })

-- Keep cursor centered when scrolling
keyset("n", "<C-d>", "<C-d>zz", { desc = "Scroll down half page" })
keyset("n", "<C-u>", "<C-u>zz", { desc = "Scroll up half page" })

-- Diagnostic navigation (global, not per-buffer)
keyset("n", "[g", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
keyset("n", "]g", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
keyset("n", "<leader>ce", vim.diagnostic.open_float, { desc = "Diagnostic float" })
