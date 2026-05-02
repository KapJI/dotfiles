-- In-buffer markdown rendering: headers, lists, code blocks, tables,
-- checkboxes, links — drawn over the raw text by treesitter. The cursor
-- line stays raw so you can edit; everything else renders.
--
-- Toggle with :RenderMarkdown toggle (mapped below to <leader>mr).
return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ft = { "markdown" },
  opts = {
    file_types = { "markdown" },
    code     = { sign = false, width = "block", min_width = 60 },
    heading  = { sign = false, position = "inline" },
    checkbox = {
      unchecked = { icon = "󰄱 " },
      checked   = { icon = "󰱒 " },
    },
  },
  keys = {
    { "<leader>mr", "<Cmd>RenderMarkdown toggle<CR>", desc = "Toggle markdown render" },
  },
}
