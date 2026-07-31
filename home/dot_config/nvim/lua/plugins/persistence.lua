-- persistence.nvim — auto-save and restore nvim sessions per cwd.
-- snacks.dashboard auto-detects this plugin and adds an "s" key on the
-- dashboard for restore-cwd-session. The leader keys below cover the
-- mid-session and cross-project cases.
local sensitive = require("config.sensitive")

return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {},
  config = function(_, opts)
    -- persistence v3 has no `options` opt (only dir/need/branch); the
    -- session contents are controlled by 'sessionoptions'. Trim
    -- runtimepath out of the saved session (it doesn't change between
    -- launches and bloats the file); keep buffers, layout, cwd,
    -- tabpages, and globals. No `help`: the PersistenceSavePre cleanup
    -- below strips help windows as transient (same as minimap/undotree),
    -- so `help` here was inert — dropped to match the actual behavior.
    vim.o.sessionoptions = "buffers,curdir,tabpages,winsize,globals,skiprtp"

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
    -- Named, cleared augroup (deliberately NOT "persistence" — that's the
    -- plugin's own group, deleted by name in M.stop()) so re-sourcing this
    -- spec replaces the handler instead of stacking duplicates.
    local group = vim.api.nvim_create_augroup("user_persistence", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistenceSavePre",
      group = group,
      callback = function()
        local function is_real_file(buf)
          local name = vim.api.nvim_buf_get_name(buf)
          if vim.bo[buf].buftype ~= "" or name == "" or vim.fn.filereadable(name) ~= 1 then
            return false
          end
          -- Treat sensitive buffers as non-real so they're closed/dropped
          -- before :mksession. `chezmoi edit <secret>` opens a decrypted
          -- plaintext at a …/chezmoi-encrypted<rand>/… temp that chezmoi
          -- deletes once the editor exits; persisting a badd/edit for it both
          -- restores a stale, gone path next session AND records the secret's
          -- filename in the plaintext session file. Same predicate we already
          -- use to withhold persistent undo (SSH, .aws, .netrc, .env, chezmoi
          -- temps), checked against the resolved path too (a symlink whose
          -- name is innocuous but points into ~/.ssh).
          local resolved = (vim.uv or vim.loop).fs_realpath(name) or name
          if sensitive.is_sensitive_path(name) or sensitive.is_sensitive_path(resolved) then
            return false
          end
          return true
        end

        -- Whether the cleanup may destroy `buf`. Real files stay in the
        -- session. Of the transient buffers is_real_file rejects, spare a
        -- *non-sensitive* one holding unsaved edits — force-deleting it
        -- would lose data. This fires only at VimLeavePre today
        -- (persistence has no mid-session save and no save key is bound),
        -- where :qa + 'confirm' has already resolved modifications, so the
        -- guard is insurance against a future mid-session save. A sensitive
        -- buffer is destroyed even when modified: mksession must not record
        -- the secret's path, and an unsaved secret at exit is already being
        -- abandoned by the quit.
        local function may_destroy(buf)
          if is_real_file(buf) then
            return false
          end
          if not vim.bo[buf].modified then
            return true
          end
          local name = vim.api.nvim_buf_get_name(buf)
          local resolved = (vim.uv or vim.loop).fs_realpath(name) or name
          return sensitive.is_sensitive_path(name) or sensitive.is_sensitive_path(resolved)
        end

        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_is_valid(win) then
            local buf = vim.api.nvim_win_get_buf(win)
            if may_destroy(buf) then
              pcall(vim.api.nvim_win_close, win, true)
            end
          end
        end

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and may_destroy(buf) then
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
          end
        end
      end,
    })
  end,
  keys = {
    {
      "<leader>ss",
      function()
        require("persistence").load()
      end,
      desc = "Session: restore (cwd)",
    },
    {
      "<leader>sl",
      function()
        require("persistence").load({ last = true })
      end,
      desc = "Session: restore last used",
    },
    {
      "<leader>sp",
      function()
        require("persistence").select()
      end,
      desc = "Session: pick",
    },
    {
      "<leader>sd",
      function()
        require("persistence").stop()
      end,
      desc = "Session: don't save on exit",
    },
  },
}
