-- Show available keybindings
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    require("which-key").setup({ delay = 1000 })
    require("which-key").add({
      { "<leader>f", group = "Find" },
      { "<leader>c", group = "Code" },
      { "<leader>g", group = "Git" },
      { "<leader>q", group = "Quickfix" },
    })
  end,
}
