return {
  -- Syntax highlighting and code understanding via AST
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",         -- v1.0 rewrite on `main` requires nvim 0.12 nightly
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
