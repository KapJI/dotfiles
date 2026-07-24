-- Global, plugin-independent keymaps. Plugin-specific keymaps live alongside
-- their plugin spec or in LspAttach (config/lsp.lua).

local keyset = vim.keymap.set

-- Toggle verbose listchars (presets single-sourced in config/options.lua)
local listchars = require("config.options").listchars
keyset("n", "<C-l>", function()
  if vim.opt.listchars:get().eol then
    vim.opt.listchars = listchars.minimal
  else
    vim.opt.listchars = listchars.full
  end
end, { desc = "Toggle verbose listchars" })

-- System clipboard. vim.g.clipboard is left unset, so Neovim picks a
-- provider by environment: pbcopy on macOS; otherwise inside tmux it hands
-- off to tmux's buffer (`tmux load-buffer -w`, which relays to the local
-- terminal over OSC 52); bare SSH without tmux uses Neovim's own OSC 52.
keyset({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
keyset({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from clipboard" })

-- Toggle comments
keyset("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment" })
keyset("v", "<leader>/", "gc", { remap = true, desc = "Toggle comment" })

-- Keep selection after indenting, so you can press > or < repeatedly
-- instead of re-selecting with `gv` each time.
keyset("v", "<", "<gv", { desc = "Indent left, keep selection" })
keyset("v", ">", ">gv", { desc = "Indent right, keep selection" })

-- Search highlight is cleared with <Esc> (bound in multicursor.lua:
-- clears cursors when active, :nohlsearch otherwise).

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
end, {
  nargs = 1,
  complete = function()
    return { "on", "off" }
  end,
})

-- Keep cursor centered when scrolling
keyset("n", "<C-d>", "<C-d>zz", { desc = "Scroll down half page" })
keyset("n", "<C-u>", "<C-u>zz", { desc = "Scroll up half page" })

-- Diagnostic navigation (global, not per-buffer)
keyset("n", "<leader>ce", vim.diagnostic.open_float, { desc = "Diagnostic float" })

-- Emacs-style readline keys missing from default vim cmdline.
-- Vim already provides: <C-e> eol, <C-w> del-word-back, <C-u> del-to-start,
-- <S-Left>/<S-Right> word movement. We add <C-a> bol (overriding vim's
-- complete-all-matches) and <C-k> kill-to-end (no vim equivalent).
keyset("c", "<C-a>", "<Home>", { desc = "Cmdline: beginning of line (emacs)" })
keyset("c", "<C-k>", function()
  local pos = vim.fn.getcmdpos()
  local line = vim.fn.getcmdline()
  vim.fn.setcmdline(line:sub(1, pos - 1))
end, { desc = "Cmdline: kill to end" })

-- Notification history (noice routes vim.notify → nvim-notify).
keyset("n", "<leader>Nh", "<Cmd>NoiceFzf<CR>", { desc = "Notifications: history (fzf)" })
keyset("n", "<leader>Nl", "<Cmd>NoiceLast<CR>", { desc = "Notifications: last popup" })
keyset("n", "<leader>Nd", "<Cmd>NoiceDismiss<CR>", { desc = "Notifications: dismiss visible" })
