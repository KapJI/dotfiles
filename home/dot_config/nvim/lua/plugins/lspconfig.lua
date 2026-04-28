-- LSP defaults (keymaps + server config live in lua/config/lsp.lua,
-- which is loaded by init.lua after lazy setup completes).
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
}
