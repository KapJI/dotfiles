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
  config = function(_, opts)
    require("persistence").setup(opts)

    -- Strip transient plugin buffers (neominimap, undotree, [No Name]
    -- scratch, etc.) before persistence runs `:mksession`. The plugin
    -- emits a User PersistenceSavePre autocmd; the `pre_save` opts key
    -- often shown elsewhere doesn't exist in this version.
    --
    -- Two-pass cleanup:
    --   1. Close every window whose buffer isn't a real file on disk.
    --      This kills `enew` fallback windows mksession would create
    --      for plugin panels (e.g. minimap, undotree).
    --   2. Delete every remaining non-file buffer (covers hidden listed
    --      buffers like [Scratch] that mksession's `badd` would record).
    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistenceSavePre",
      callback = function()
        local function is_real_file(buf)
          local name    = vim.api.nvim_buf_get_name(buf)
          local buftype = vim.bo[buf].buftype
          return buftype == ""
            and name ~= ""
            and vim.fn.filereadable(name) == 1
        end

        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_is_valid(win) then
            local buf = vim.api.nvim_win_get_buf(win)
            if not is_real_file(buf) then
              pcall(vim.api.nvim_win_close, win, true)
            end
          end
        end

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and not is_real_file(buf) then
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
          end
        end
      end,
    })
  end,
  keys = {
    { "<leader>ss", function() require("persistence").load() end,                desc = "Session: restore (cwd)" },
    { "<leader>sl", function() require("persistence").load({ last = true }) end, desc = "Session: restore last used" },
    { "<leader>sp", function() require("persistence").select() end,              desc = "Session: pick" },
    { "<leader>sd", function() require("persistence").stop() end,                desc = "Session: don't save on exit" },
  },
}
