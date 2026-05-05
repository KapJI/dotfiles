-- snacks.nvim — adopting only the dashboard module for now.
-- Replaces alpha-nvim with built-in recents/projects/git sections and
-- a 2-pane layout. All other snacks modules are off by default;
-- enable individually when needed (see the bottom of this file for a list).
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy     = false,
  ---@type snacks.Config
  opts = {
    dashboard = {
      preset = {
        header = table.concat({
          "                                                ",
          "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
          "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
          "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
          "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
          "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
          "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
          "                                                ",
        }, "\n"),
        keys = {
          { icon = "󰈞", key = "f", desc = "Find file",       action = ":FzfLua files" },
          { icon = "󰋚", key = "r", desc = "Recent files",    action = ":FzfLua oldfiles" },
          { icon = "󰦛", key = "s", desc = "Restore session", section = "session" },
          { icon = "󰍉", key = "g", desc = "Live grep",       action = ":FzfLua live_grep" },
          { icon = "󰈙", key = "e", desc = "New file",        action = ":enew" },
          { icon = "󰉋", key = ".", desc = "Browse cwd",      action = ":Oil" },
          { icon = "󰒲", key = "l", desc = "Lazy",            action = ":Lazy" },
          { icon = "󰏖", key = "m", desc = "Mason",           action = ":Mason" },
          { icon = "󰗼", key = "q", desc = "Quit",            action = ":qa" },
        },
      },
      -- Two-pane layout: left = banner + buttons + startup line,
      -- right = recents + projects + tips.
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },

        -- Pad right pane down so its first section (Recent Files) aligns
        -- vertically with "Find file" on the left. The NEOVIM ASCII header
        -- is 8 lines tall; tweak this if alignment drifts.
        { pane = 2, text = "\n\n\n\n\n\n\n\n\n" },
        { pane = 2, title = "󰋚 Recent Files", section = "recent_files", indent = 2, padding = 1 },
        { pane = 2, title = "󰉋 Projects",     section = "projects",     indent = 2, padding = 1 },
        function()
          local body = require("config.dashboard-tips").pick(3)[1] -- single Text item with \n
          return {
            pane = 2,
            text = {
              { "󰛨 Tips of the Day\n", hl = "title" },
              { body[1], hl = "Comment" },
            },
            padding = 1,
          }
        end,

        { section = "startup" },
      },
    },

    -- Disable expensive features (treesitter, LSP, syntax, folds, undofile)
    -- when a buffer's file is above ~1.5MB. Saves nvim from stalls on
    -- large logs, JSON dumps, or minified bundles.
    bigfile      = { enabled = true },

    -- Notifications are owned by noice.nvim → nvim-notify (see noice.lua).
    -- snacks.notifier is left here only as a documented off-switch so its
    -- prior config is recoverable in git history if we want to flip back.
    notifier     = { enabled = false },

    -- Other snacks modules — disabled until we explicitly want them.
    quickfile    = { enabled = false },
    scope        = { enabled = false },
    scroll       = { enabled = false },
    statuscolumn = { enabled = false },
    words        = { enabled = false },
    indent       = { enabled = false },

    -- Replace vim.ui.input (cmdline prompt) with a floating window.
    -- Most input prompts already go through inc-rename / fzf-lua;
    -- this catches the remaining vim.ui.input calls for visual consistency.
    input        = { enabled = true },
    picker       = { enabled = false },
    explorer     = { enabled = false },

    -- Hotkey-toggle floating shell. Real terminal work still belongs in
    -- wezterm / tmux panes (persistent scrollback, fingers, full copy-mode);
    -- this is just a quick scratch shell for one-off commands without
    -- leaving nvim's window focus. Toggle with <leader>tt; <Esc><Esc>
    -- exits terminal mode (snacks default).
    terminal     = { enabled = true },
  },
  keys = {
    {
      "<leader>tt",
      function()
        Snacks.terminal.toggle(nil, {
          win = {
            position    = "float",
            border      = "rounded",
            title       = " Terminal ",
            title_pos   = "center",
            width       = 0.8,    -- 80% of editor width
            height      = 0.8,    -- 80% of editor height
          },
        })
      end,
      mode = { "n", "t" },
      desc = "Toggle floating terminal",
    },
  },
}
