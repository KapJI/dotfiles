-- Diff viewer and file history
return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<CR>",          silent = true, desc = "Diff working tree" },
    { "<leader>gl", "<cmd>DiffviewFileHistory %<CR>", silent = true, desc = "File history" },
    { "<leader>gL", "<cmd>DiffviewFileHistory<CR>",   silent = true, desc = "Repo history" },
  },
  config = function()
    require("diffview").setup({
      keymaps = {
        view               = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } } },
        file_panel         = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } } },
        file_history_panel = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } } },
      },
    })
  end,
}
