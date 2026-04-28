-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Core options and behaviour (no plugins required)
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Plugins
require("lazy").setup("plugins", {
  install = { colorscheme = { "catppuccin-mocha" } },
  change_detection = { notify = false },
  ui = { border = "rounded" },
})

-- Post-plugin configuration (LSP, UI tweaks that depend on highlights/lualine)
require("config.lsp")
require("config.ui")
