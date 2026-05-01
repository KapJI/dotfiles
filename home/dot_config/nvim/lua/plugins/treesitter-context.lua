return {
  -- Sticky header showing the surrounding function/class/etc. as you scroll
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      max_lines = 3,        -- cap header height
      multiline_threshold = 1,
      mode = "cursor",      -- show context based on cursor position (vs window top)
      separator = nil,      -- thin underline; set to "─" or similar to make it visible
      zindex = 20,
    },
    keys = {
      -- gitsigns owns [c / ]c for hunk navigation; use [x / ]x for context.
      -- (No "next context" — context lives above the cursor by definition.)
      {
        "[x",
        function() require("treesitter-context").go_to_context(vim.v.count1) end,
        desc = "Jump to surrounding context",
      },
    },
  },
}
