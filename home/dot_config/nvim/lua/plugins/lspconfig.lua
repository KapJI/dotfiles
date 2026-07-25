-- LSP defaults (keymaps + server config live in lua/config/lsp.lua,
-- which is loaded by init.lua after lazy setup completes).
-- lazy = false, not event-triggered: config.lsp calls vim.lsp.enable()
-- for every server at startup and needs this plugin's server configs
-- (cmd, root markers, filetypes) already registered when it runs.
return {
  "neovim/nvim-lspconfig",
  lazy = false,
}
