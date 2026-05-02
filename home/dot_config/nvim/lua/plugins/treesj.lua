-- treesj: treesitter-aware split/join for multi-line constructs (tables,
-- dicts, function args, arrays). One keystroke to toggle one-liner ↔
-- multi-line, preserving commas, trailing-comma rules, and nested structure.
return {
  {
    "Wansmer/treesj",
    cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
    keys = {
      { "<leader>j", "<Cmd>TSJToggle<CR>", desc = "Toggle split/join (treesj)" },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      use_default_keymaps = false, -- we set our own above
      max_join_length     = 200,    -- don't join into absurdly long lines
      cursor_behavior     = "hold", -- keep cursor on the same node after toggle
    },
  },
}
