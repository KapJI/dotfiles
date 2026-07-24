-- nvim-lint: run CLI linters and surface their output as nvim diagnostics.
-- Complement to conform.nvim (which formats); this catches style/quality
-- issues that LSPs don't.
--
-- Linter binaries: luacheck ships from packages.yaml (nix, fleet-wide);
-- yamllint / markdownlint-cli2 come from mason (:MasonInstall yamllint
-- markdownlint-cli2). luacheck reads .luacheckrc at the repo root.
-- (optional: shellcheck — bashls auto-uses it for .sh/.bash; only listed
--  here for .zsh files which bashls doesn't attach to)
return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        lua = { "luacheck" },
        yaml = { "yamllint" },
        markdown = { "markdownlint-cli2" },
        -- Uncomment when you want shellcheck on zsh files (sh/bash already
        -- covered by bashls). shellcheck doesn't fully grok zsh syntax;
        -- expect noise around zstyle/parameter expansions.
        -- zsh   = { "shellcheck" },
      }

      -- Trigger lints on open, save, and when leaving insert mode (so you
      -- see diagnostics quickly without spamming linters on every
      -- keystroke).
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })

      -- The autocmd can't cover the buffer whose BufReadPost triggered
      -- this very load: lazy re-fires the event after setup, but before
      -- filetype detection has settled, so try_lint finds no linter for
      -- it. Lint the initial buffer with one direct, scheduled pass.
      vim.schedule(function()
        lint.try_lint()
      end)

      -- Manual trigger
      vim.keymap.set("n", "<leader>cl", function()
        lint.try_lint()
      end, { desc = "Lint current buffer" })
    end,
  },
}
