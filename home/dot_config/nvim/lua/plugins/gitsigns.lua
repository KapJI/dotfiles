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
        keyset("n", "]c", function() gs.nav_hunk("next") end, { buffer = bufnr, silent = true, desc = "Next git hunk" })
        keyset("n", "[c", function() gs.nav_hunk("prev") end, { buffer = bufnr, silent = true, desc = "Previous git hunk" })
        keyset("n", "<leader>gs", gs.stage_hunk, { buffer = bufnr, silent = true, desc = "Stage hunk" })
        keyset("n", "<leader>gu", gs.reset_hunk, { buffer = bufnr, silent = true, desc = "Undo/reset hunk" })
        keyset("n", "<leader>gp", gs.preview_hunk, { buffer = bufnr, silent = true, desc = "Preview hunk" })
        keyset("n", "<leader>gb", gs.blame_line, { buffer = bufnr, silent = true, desc = "Blame line" })
      end,
    })
  end,
}
