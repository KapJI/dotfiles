-- multicursor.nvim — Sublime-style multi-cursor on demand.
-- Bindings avoid <C-x> to keep dial.nvim's decrement free.
return {
  "jake-stewart/multicursor.nvim",
  event = "VeryLazy",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local keyset = vim.keymap.set

    -- Add a cursor at the next match of the word under cursor (Sublime-style).
    keyset({ "n", "x" }, "<C-n>",      function() mc.matchAddCursor(1)  end, { desc = "Multi-cursor: add at next match" })
    -- Skip the current match, add one at the next.
    keyset({ "n", "x" }, "<leader>mn", function() mc.matchSkipCursor(1) end, { desc = "Multi-cursor: skip + next match" })
    -- One cursor per line in the visual selection.
    keyset({ "n", "x" }, "<leader>ml", function() mc.lineAddCursor(1) end,  { desc = "Multi-cursor: add cursor below" })
    -- Align all cursors to the same column (after editing different-width text).
    keyset({ "n", "x" }, "<leader>ma", mc.alignCursors,                      { desc = "Multi-cursor: align columns" })
    -- Esc clears cursors when in multi-cursor mode; otherwise behaves normally.
    keyset("n", "<Esc>", function()
      if mc.hasCursors() then mc.clearCursors() else vim.cmd("nohlsearch") end
    end, { desc = "Clear multi-cursors / search highlight" })
  end,
}
