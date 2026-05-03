-- smart-splits.nvim — multiplexer-aware split navigation.
-- Replaces vim-tmux-navigator and adds resize + swap.
-- Cross-tool keymap convention:
--   Alt+hjkl              — navigate (nvim split / tmux pane / wezterm pane)
--   Alt+Shift+HJKL        — resize toward that edge (3 cells per press)
--   <leader>w + HJKL      — swap nvim split contents (nvim-only feature)
return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  opts = {
    -- Cycle when reaching screen edges instead of doing nothing.
    at_edge = "wrap",
    cursor_follows_swapped_bufs = true,
    -- Default resize step in cells.
    default_amount = 3,
    -- Multiplexer integrations are auto-detected via $TMUX / $WEZTERM_PANE.
    multiplexer_integration = nil, -- nil = auto
  },
  keys = {
    -- Navigation — same keys as the old vim-tmux-navigator setup.
    { "<M-h>", function() require("smart-splits").move_cursor_left()  end, desc = "Pane: left" },
    { "<M-j>", function() require("smart-splits").move_cursor_down()  end, desc = "Pane: down" },
    { "<M-k>", function() require("smart-splits").move_cursor_up()    end, desc = "Pane: up" },
    { "<M-l>", function() require("smart-splits").move_cursor_right() end, desc = "Pane: right" },

    -- Resize — Alt+Shift+HJKL, 3 cells per press.
    { "<M-S-h>", function() require("smart-splits").resize_left()  end, desc = "Resize ←" },
    { "<M-S-j>", function() require("smart-splits").resize_down()  end, desc = "Resize ↓" },
    { "<M-S-k>", function() require("smart-splits").resize_up()    end, desc = "Resize ↑" },
    { "<M-S-l>", function() require("smart-splits").resize_right() end, desc = "Resize →" },

    -- Swap nvim split contents (no equivalent in tmux/wezterm).
    { "<leader>wH", function() require("smart-splits").swap_buf_left()  end, desc = "Swap pane ←" },
    { "<leader>wJ", function() require("smart-splits").swap_buf_down()  end, desc = "Swap pane ↓" },
    { "<leader>wK", function() require("smart-splits").swap_buf_up()    end, desc = "Swap pane ↑" },
    { "<leader>wL", function() require("smart-splits").swap_buf_right() end, desc = "Swap pane →" },
  },
}
