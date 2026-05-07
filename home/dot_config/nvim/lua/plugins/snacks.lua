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

    -- Smooth scroll animation for <C-d>/<C-u>/<C-f>/<C-b>/zz/etc.
    -- Override snacks defaults (total=200ms / repeat 50ms) with snappier
    -- timings so motion feels closer to instant. Step kept at 10ms so
    -- the animation still has multiple frames.
    scroll       = {
      enabled        = true,
      animate        = { duration = { total = 150 } },
      animate_repeat = { duration = { total = 40 } },
    },

    -- Other snacks modules — disabled until we explicitly want them.
    quickfile    = { enabled = false },
    scope        = { enabled = false },
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
    {
      "<leader>gg",
      function()
        -- Two issues with snacks.lazygit's defaults:
        --
        -- 1. snacks.lazygit uses style = "lazygit" (empty) instead of
        --    style = "minimal", so global statuscolumn (statuscol.nvim),
        --    number, foldcolumn, list all leak into the float and trim
        --    5+ cells off lazygit's render area. Clear via wo overrides.
        --
        -- 2. snacks.terminal auto-enters terminal mode immediately after
        --    termopen. gocui (lazygit's TUI library) races with nvim's
        --    mode entry: lazygit's first paint lands while nvim is still
        --    transitioning to terminal mode, ending up 1 col left-shifted.
        --    Bare `:terminal lazygit` (no auto-startinsert) doesn't trip
        --    this; deferring startinsert by ~50 ms also doesn't.
        --    Disable snacks's auto-insert and call `startinsert` ourselves
        --    after a short defer.
        Snacks.lazygit({
          win = {
            wo = {
              statuscolumn   = "",
              number         = false,
              relativenumber = false,
              foldcolumn     = "0",
              list           = false,
            },
          },
          start_insert = false,
          auto_insert  = false,
          interactive  = false, -- avoids the gocui+startinsert render race
          auto_close   = true,  -- override the `interactive=false` cascade so the float still closes when lazygit exits (otherwise we'd be stuck on "[Process exited 0]" needing a second q)
        })

        -- Wait for lazygit's first paint to STABILIZE before entering
        -- terminal mode — going to insert mode while gocui is still
        -- emitting cells re-races the original shift bug. We use two
        -- complementary signals:
        --   1. Buffer reaches window height (lazygit renders full-screen).
        --   2. Line count stops changing for two consecutive polls.
        -- Whichever fires first wins. Hard cap of 2 s as a safety belt.
        local buf   = vim.api.nvim_get_current_buf()
        local win   = vim.api.nvim_get_current_win()
        local timer = vim.uv.new_timer()
        local last_count = -1
        local stable_for = 0
        local elapsed    = 0
        timer:start(50, 50, vim.schedule_wrap(function()
          elapsed = elapsed + 50
          if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
            timer:stop(); timer:close()
            return
          end
          local count    = vim.api.nvim_buf_line_count(buf)
          local target   = vim.api.nvim_win_get_height(win)
          stable_for     = (count == last_count) and (stable_for + 1) or 0
          last_count     = count

          local done = count >= target or stable_for >= 2 or elapsed >= 2000
          if done then
            timer:stop(); timer:close()
            if vim.api.nvim_get_current_win() == win then
              vim.cmd("startinsert")
            end
          end
        end))
      end,
      desc = "Lazygit (floating)",
    },
  },
}
