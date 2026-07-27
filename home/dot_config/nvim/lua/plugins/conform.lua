-- conform.nvim: per-filetype CLI formatter dispatcher with format-on-save.
-- Falls back to vim.lsp.buf.format() for filetypes not in formatters_by_ft,
-- so this is strictly additive to the existing LSP setup.
--
-- Formatter binaries are installed fleet-wide via .data/packages.yaml
-- (nix): stylua, shfmt, prettier, taplo, goimports, plus ruff/nixfmt/
-- rustfmt under their own entries. conform finds them on PATH. Exception:
-- terraform_fmt needs the terraform binary (unfree in nixpkgs), usually
-- absent — so it's registered only when `terraform` is on PATH (executable()
-- gate below). Registering it unconditionally is NOT a silent no-op: with
-- notify_on_error, every .tf/.tfvars save toasts "Formatters unavailable for
-- terraform file". The gate self-heals if terraform is ever installed.
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format buffer/selection",
      },
    },
    opts = function()
      local formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_organize_imports", "ruff_format" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        -- No zsh entry: shfmt has no zsh dialect and errors out on
        -- zsh-only syntax, turning every save into an error toast.
        yaml = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        markdown = { "prettier" },
        nix = { "nixfmt" },
        go = { "goimports" }, -- goimports already applies gofmt formatting; a second gofmt pass is redundant
        rust = { "rustfmt" },
        toml = { "taplo" },
      }
      -- Only wire up terraform_fmt when terraform is actually installed (see
      -- header) — otherwise every .tf/.tfvars save toasts an error.
      if vim.fn.executable("terraform") == 1 then
        formatters_by_ft.terraform = { "terraform_fmt" }
        formatters_by_ft["terraform-vars"] = { "terraform_fmt" }
      end
      return {
        formatters_by_ft = formatters_by_ft,
        format_on_save = function(bufnr)
          -- Skip format-on-save for buffers explicitly opted out (vim.b.disable_autoformat=true)
          -- or if the global flag is set (vim.g.disable_autoformat=true).
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          return { timeout_ms = 1500, lsp_format = "fallback" }
        end,
        notify_on_error = true,
      }
    end,
  },
}
