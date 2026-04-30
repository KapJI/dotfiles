return {
  -- Syntax highlighting and code understanding via AST
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",         -- v1 rewrite; requires nvim 0.11+
    lazy = false,            -- main does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        "bash", "json", "lua", "markdown", "nix", "python",
        "terraform", "typescript", "yaml",
      })

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          if pcall(vim.treesitter.start, args.buf) then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
