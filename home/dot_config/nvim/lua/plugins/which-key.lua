-- Show available keybindings
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    require("which-key").setup({ delay = 1000 })
    require("which-key").add({
      { "<leader>c", group = "Code" },
      { "<leader>f", group = "Find" },
      { "<leader>g", group = "Git" },
      { "<leader>m", group = "Multicursor / Markdown" },
      { "<leader>n", group = "Navigation" },
      { "<leader>q", group = "Quickfix" },
      { "<leader>s", group = "Session" },
      { "<leader>t", group = "Terminal" },
      { "<leader>w", group = "Window swap" },
      { "<leader>x", group = "eXchange (swap)" },
    })
  end,
}
