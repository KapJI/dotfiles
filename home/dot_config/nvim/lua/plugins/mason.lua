-- mason.nvim installs LSP servers, formatters, linters, and DAPs into
-- ~/.local/share/nvim/mason/bin/ (auto-prepended to nvim's $PATH).
--
-- mason-lspconfig.nvim's automatic_enable bridges mason → vim.lsp.enable():
-- any server installed via :Mason gets vim.lsp.enable()-ed automatically on
-- next nvim start, with no per-server entry in lua/config/lsp.lua.
-- Customization (settings, on_attach overrides) still goes in lsp.lua via
-- vim.lsp.config("server_name", { ... }) — automatic_enable picks that up.
return {
  {
    "mason-org/mason.nvim",
    lazy = false,                       -- load early so PATH is set before lspconfig event fires
    priority = 200,                     -- before mason-lspconfig (default priority 100)
    build = ":MasonUpdate",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason: LSP/tools manager" } },
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = false,                       -- automatic_enable needs to fire at startup
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {},             -- don't force-install anything; user picks via :Mason
      automatic_enable = true,           -- auto vim.lsp.enable() any mason-installed server
    },
  },
}
