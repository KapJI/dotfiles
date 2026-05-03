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
      -- Jump to whichever surrounding scope the sticky header is showing
      -- (function / class / for-block / etc., whatever's nearest). Pairs
      -- with mini.bracketed [x/]x (conflict markers): lowercase x for
      -- inline marker pairs, capital X for enclosing scope. Asymmetric —
      -- no ]X because context is always above the cursor.
      {
        "[X",
        function() require("treesitter-context").go_to_context(vim.v.count1) end,
        desc = "Jump to surrounding context",
      },
    },
  },
}
