return {
  -- Syntax highlighting and code understanding via AST
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",         -- frozen, kept for nvim < 0.11 compat; `main` rewrite needs newer nvim
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "json", "lua", "markdown", "nix", "python",
          "terraform", "typescript", "yaml",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
