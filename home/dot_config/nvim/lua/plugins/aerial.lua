-- stevearc/aerial.nvim — symbol outline. Backends fall through in order:
-- LSP first (rich, accurate), treesitter fallback (works on shells,
-- markdown, etc. where no LSP is attached), markdown / man for those
-- specific filetypes.
--
-- Why aerial over outline.nvim: aerial keeps working on buffers without
-- LSP via the treesitter backend (matters for chezmoi shell scripts and
-- raw markdown). Same author as oil.nvim and conform.nvim — the
-- maintainership signal we already trust.
return {
  "stevearc/aerial.nvim",
  cmd = { "AerialToggle", "AerialNavToggle" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    backends = { "lsp", "treesitter", "markdown", "man" },
    layout   = { default_direction = "right", min_width = 25 },
    autojump = true,           -- moving in the outline jumps the source too
    show_guides = true,
    highlight_on_jump = 250,   -- briefly highlight the destination line
  },
  keys = {
    { "<leader>co", "<cmd>AerialToggle!<cr>",   desc = "Code outline (aerial)" },
    { "<leader>cO", "<cmd>AerialNavToggle<cr>", desc = "Code outline picker" },
  },
}
