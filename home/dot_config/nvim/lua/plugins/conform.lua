-- conform.nvim: per-filetype CLI formatter dispatcher with format-on-save.
-- Falls back to vim.lsp.buf.format() for filetypes not in formatters_by_ft,
-- so this is strictly additive to the existing LSP setup.
--
-- Install missing formatter binaries via :MasonInstall <name> (e.g. stylua,
-- shfmt, prettier, nixpkgs-fmt, taplo). conform finds them on PATH the same
-- way mason-lspconfig finds language servers.
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true, lsp_fallback = true }) end,
        mode = { "n", "v" },
        desc = "Format buffer/selection",
      },
    },
    opts = {
      formatters_by_ft = {
        lua            = { "stylua" },
        python         = { "ruff_organize_imports", "ruff_format" },
        sh             = { "shfmt" },
        bash           = { "shfmt" },
        zsh            = { "shfmt" },
        yaml           = { "prettier" },
        json           = { "prettier" },
        jsonc          = { "prettier" },
        markdown       = { "prettier" },
        nix            = { "nixpkgs_fmt" },
        go             = { "goimports", "gofmt" },
        rust           = { "rustfmt" },
        terraform      = { "terraform_fmt" },
        ["terraform-vars"] = { "terraform_fmt" },
        toml           = { "taplo" },
      },
      format_on_save = function(bufnr)
        -- Skip format-on-save for buffers explicitly opted out (vim.b.disable_autoformat=true)
        -- or if the global flag is set (vim.g.disable_autoformat=true).
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_fallback = true }
      end,
      notify_on_error = true,
    },
  },
}
