-- Diff viewer and file history
return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>gd", "<Cmd>DiffviewOpen<CR>",          silent = true, desc = "Diff working tree" },
    { "<leader>gl", "<Cmd>DiffviewFileHistory %<CR>", silent = true, desc = "File history" },
    { "<leader>gL", "<Cmd>DiffviewFileHistory<CR>",   silent = true, desc = "Repo history" },
  },
  config = function()
    require("diffview").setup({
      keymaps = {
        view               = { { "n", "q", "<Cmd>DiffviewClose<CR>", { desc = "Close diffview" } } },
        file_panel         = { { "n", "q", "<Cmd>DiffviewClose<CR>", { desc = "Close diffview" } } },
        file_history_panel = { { "n", "q", "<Cmd>DiffviewClose<CR>", { desc = "Close diffview" } } },
      },
    })
  end,
}
