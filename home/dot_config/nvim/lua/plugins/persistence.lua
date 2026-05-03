-- persistence.nvim — auto-save and restore nvim sessions per cwd.
-- snacks.dashboard auto-detects this plugin and adds an "s" key on the
-- dashboard for restore-cwd-session. The leader keys below cover the
-- mid-session and cross-project cases.
return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {
    -- Trim runtimepath out of the saved session: it doesn't change
    -- between launches and bloats the file. Keep buffers, layout,
    -- cwd, tabpages, help windows, and globals.
    options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
  },
  keys = {
    { "<leader>ss", function() require("persistence").load() end,                desc = "Session: restore (cwd)" },
    { "<leader>sl", function() require("persistence").load({ last = true }) end, desc = "Session: restore last used" },
    { "<leader>sp", function() require("persistence").select() end,              desc = "Session: pick" },
    { "<leader>sd", function() require("persistence").stop() end,                desc = "Session: don't save on exit" },
  },
}
