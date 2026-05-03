-- Scrollbar with gitsigns/diagnostics integration
return {
  "petertriho/nvim-scrollbar",
  event = "VeryLazy",
  dependencies = { "lewis6991/gitsigns.nvim" },
  config = function()
    require("scrollbar").setup({
      handle = { color = "#585b70" },   -- Surface2
      marks = {
        Search    = { color = "#f9e2af" },  -- Yellow
        Error     = { color = "#f38ba8" },  -- Red
        Warn      = { color = "#fab387" },  -- Peach
        Info      = { color = "#89b4fa" },  -- Blue
        Hint      = { color = "#94e2d5" },  -- Teal
        Misc      = { color = "#cba6f7" },  -- Mauve
        GitAdd    = { color = "#a6e3a1" },  -- Green
        GitChange = { color = "#f9e2af" },  -- Yellow
        GitDelete = { color = "#f38ba8" },  -- Red
      },
    })
    require("scrollbar.handlers.gitsigns").setup()
  end,
}
