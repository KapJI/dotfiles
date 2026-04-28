-- Tabline
return {
  "akinsho/bufferline.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim" },
  event = "VeryLazy",
  config = function()
    require("bufferline").setup({
      highlights = require("catppuccin.special.bufferline").get_theme(),
      options = {
        mode = "tabs",
        show_buffer_close_icons = true,
        show_close_icon = false,
        modified_icon = "✎",
        diagnostics = "nvim_lsp",
        separator_style = "slant",
        always_show_bufferline = false,
        show_tab_indicators = false,
      },
    })
  end,
}
