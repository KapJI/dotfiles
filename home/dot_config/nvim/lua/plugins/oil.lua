-- File explorer
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Oil",
  keys = {
    { "-", "<cmd>Oil<CR>", silent = true, desc = "Open file explorer" },
  },
  config = function() require("oil").setup() end,
}
