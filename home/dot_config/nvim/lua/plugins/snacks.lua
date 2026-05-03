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
          { icon = "󰈞", key = "f", desc = "Find file",    action = ":FzfLua files" },
          { icon = "󰋚", key = "r", desc = "Recent files", action = ":FzfLua oldfiles" },
          { icon = "󰍉", key = "g", desc = "Live grep",    action = ":FzfLua live_grep" },
          { icon = "󰈙", key = "e", desc = "New file",     action = ":enew" },
          { icon = "󰉋", key = ".", desc = "Browse cwd",   action = ":Oil" },
          { icon = "󰒲", key = "l", desc = "Lazy",         action = ":Lazy" },
          { icon = "󰏖", key = "m", desc = "Mason",        action = ":Mason" },
          { icon = "󰗼", key = "q", desc = "Quit",         action = ":qa" },
        },
      },
      -- Two-pane layout: left = banner + buttons, right = recents/projects/git/tips
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },

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

        function()
          -- Built-in startup section hardcodes align="center"; wrap it
          -- to override alignment + place into right pane.
          local s = require("snacks.dashboard").sections.startup()
          s.pane  = 2
          s.align = "left"
          return s
        end,
      },
    },

    -- Other snacks modules — disabled until we explicitly want them.
    bigfile      = { enabled = false },
    notifier     = { enabled = false },
    quickfile    = { enabled = false },
    scope        = { enabled = false },
    scroll       = { enabled = false },
    statuscolumn = { enabled = false },
    words        = { enabled = false },
    indent       = { enabled = false },
    input        = { enabled = false },
    picker       = { enabled = false },
    explorer     = { enabled = false },
  },
}
