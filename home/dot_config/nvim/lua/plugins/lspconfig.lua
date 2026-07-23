-- LSP defaults (keymaps + server config live in lua/config/lsp.lua,
-- which is loaded by init.lua after lazy setup completes).
-- No lazy-load event: mason-lspconfig (lazy = false) lists this plugin
-- as a dependency, so it loads at startup regardless — an event here
-- would only suggest a deferral that never happens.
return {
  "neovim/nvim-lspconfig",
  lazy = false,
}
