-- satellite.nvim: lightweight, treesitter-aware scrollbar with handlers for
-- diagnostics, gitsigns hunks, search results, marks, and the cursor.
-- Replaces petertriho/nvim-scrollbar; same niche, fewer redraw glitches and
-- a single-window rendering path instead of dozens of extmarks per buffer.
return {
  "lewis6991/satellite.nvim",
  event = "VeryLazy",
  opts = {
    current_only = false,           -- show on every window, not just the active one
    winblend     = 50,              -- transparency for the bar background
    zindex       = 40,
    excluded_filetypes = {
      "alpha",
      "fzf",
      "oil",
      "DiffviewFiles",
      "DiffviewFileHistory",
    },
    handlers = {
      cursor      = { enable = true, symbols = { "⎺", "⎻", "⎼", "⎽" } },
      search      = { enable = true },
      diagnostic  = { enable = true, signs = { "-", "=", "≡" }, min_severity = vim.diagnostic.severity.HINT },
      gitsigns    = { enable = true, signs = { add = "│", change = "│", delete = "-" } },
      marks       = { enable = true, show_builtins = false },  -- only user marks (a-z, A-Z)
      quickfix    = { signs = { "-", "=", "≡" } },
    },
  },
  config = function(_, opts)
    require("satellite").setup(opts)
    -- marks.nvim has no User events; refresh on idle so dm{x}/dm-/dm<space>
    -- propagate to the bar without manual :SatelliteRefresh.
    vim.api.nvim_create_autocmd("CursorHold", {
      callback = function() pcall(vim.cmd, "SatelliteRefresh") end,
    })
  end,
}
