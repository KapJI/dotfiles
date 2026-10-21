-- smart-splits.nvim — multiplexer-aware split navigation.
-- Replaces vim-tmux-navigator and adds resize + swap.
-- Cross-tool keymap convention:
--   Alt+hjkl              — navigate (nvim split / tmux pane / wezterm pane)
--   Alt+Shift+HJKL        — resize toward that edge (3 cells per press)
--   <leader>w + HJKL      — swap nvim split contents (nvim-only feature)
return {
  "smart-splits-nvim/smart-splits.nvim",
  -- Must not lazy-load: the backend announces nvim to the multiplexer
  -- (wezterm's IS_NVIM user-var) only once the plugin loads.
  lazy = false,
  dependencies = {
    "smart-splits-nvim/backend-tmux",
    {
      -- Upstream marks it unstable with breaking changes "without warning",
      -- and its request format is mirrored by hand in wezterm.lua's
      -- SMART_SPLITS_REQ handler. Bump both together.
      "smart-splits-nvim/backend-wezterm",
      commit = "ae840db696791f638c190c3e0534d2ddfcd5e6a7",
    },
  },
  opts = {
    -- v3 ships no multiplexer support and detects nothing by itself. First
    -- backend that detects wins, so the inner one (tmux) goes first. herdr
    -- has no v3 backend: in a herdr pane, moves stop at nvim's edge. herdr
    -- panes inherit the outer wezterm's env, so the wezterm backend would
    -- detect there and steer wezterm's panes instead; keep it out.
    -- move.at_edge = "wrap" and resize.amount = 3 are the v3 defaults.
    mux = {
      backend = vim.env.HERDR_ENV and { "smart-splits-backend-tmux" }
        or { "smart-splits-backend-tmux", "smart-splits-backend-wezterm" },
      -- Plain movement outside both (herdr, ssh to a bare shell) is expected,
      -- not worth a warning on every start. A broken backend still errors.
      warn_if_unusable = false,
    },
    swap = { move_cursor = true },
  },
  keys = {
    -- Navigation — same keys as the old vim-tmux-navigator setup.
    {
      "<M-h>",
      function()
        require("smart-splits").move_cursor_left()
      end,
      desc = "Pane: left",
    },
    {
      "<M-j>",
      function()
        require("smart-splits").move_cursor_down()
      end,
      desc = "Pane: down",
    },
    {
      "<M-k>",
      function()
        require("smart-splits").move_cursor_up()
      end,
      desc = "Pane: up",
    },
    {
      "<M-l>",
      function()
        require("smart-splits").move_cursor_right()
      end,
      desc = "Pane: right",
    },

    -- Resize — Alt+Shift+HJKL, 3 cells per press.
    {
      "<M-S-h>",
      function()
        require("smart-splits").resize_left()
      end,
      desc = "Resize ←",
    },
    {
      "<M-S-j>",
      function()
        require("smart-splits").resize_down()
      end,
      desc = "Resize ↓",
    },
    {
      "<M-S-k>",
      function()
        require("smart-splits").resize_up()
      end,
      desc = "Resize ↑",
    },
    {
      "<M-S-l>",
      function()
        require("smart-splits").resize_right()
      end,
      desc = "Resize →",
    },

    -- Swap nvim split contents (no equivalent in tmux/wezterm).
    {
      "<leader>wH",
      function()
        require("smart-splits").swap_buf_left()
      end,
      desc = "Swap pane ←",
    },
    {
      "<leader>wJ",
      function()
        require("smart-splits").swap_buf_down()
      end,
      desc = "Swap pane ↓",
    },
    {
      "<leader>wK",
      function()
        require("smart-splits").swap_buf_up()
      end,
      desc = "Swap pane ↑",
    },
    {
      "<leader>wL",
      function()
        require("smart-splits").swap_buf_right()
      end,
      desc = "Swap pane →",
    },
  },
}
