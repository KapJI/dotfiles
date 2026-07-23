-- Git signs in gutter
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local keyset = vim.keymap.set
    require("gitsigns").setup({
      on_attach = function(bufnr)
        -- snacks.bigfile remaps oversized buffers to filetype "bigfile";
        -- skip gitsigns there to avoid running diff on huge buffers.
        if vim.bo[bufnr].filetype == "bigfile" then return false end

        local gs = require("gitsigns")
        -- In diff windows keep the built-in ]c/[c (jump to diff change);
        -- nav_hunk has no diff-mode fallback of its own.
        keyset("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, { buffer = bufnr, silent = true, desc = "Next git hunk" })
        keyset("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, { buffer = bufnr, silent = true, desc = "Previous git hunk" })
        keyset("n", "<leader>gs", gs.stage_hunk, { buffer = bufnr, silent = true, desc = "Stage hunk" })
        keyset("n", "<leader>gu", gs.reset_hunk, { buffer = bufnr, silent = true, desc = "Undo/reset hunk" })
        keyset("n", "<leader>gp", gs.preview_hunk, { buffer = bufnr, silent = true, desc = "Preview hunk" })
        keyset("n", "<leader>gb", gs.blame_line, { buffer = bufnr, silent = true, desc = "Blame line" })
      end,
    })
  end,
}
