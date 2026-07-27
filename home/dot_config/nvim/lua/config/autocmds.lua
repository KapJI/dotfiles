-- Autocommands not specific to any plugin. Grouped under a named augroup
-- (cleared on re-source) so re-running this file — e.g. `:luafile %` while
-- editing config — replaces the handlers instead of stacking duplicates.
local augroup = vim.api.nvim_create_augroup("user_autocmds", { clear = true })

-- Never persist undo history for sensitive files. Persistent undo
-- (undofile, options.lua) otherwise leaves a decrypted copy of secrets
-- on disk indefinitely — most sharply the plaintext temp files chezmoi
-- writes when you `chezmoi edit` an age-encrypted source, which silently
-- defeats encryption-at-rest. Match SSH files (~/.ssh/*), chezmoi's
-- decrypted temps (…/chezmoi-encrypted<rand>/…), and other secret stores
-- (~/.aws/*, ~/.netrc, .env*) — see config.sensitive for the full list. Set
-- on read/create before the undofile is ever written.
--
-- Test BOTH the buffer name (always absolute here) and its symlink-
-- resolved path:
--   - the raw name catches a real file under a symlinked ~/.ssh dir,
--     whose realpath resolves elsewhere and would slip the pattern;
--   - the realpath catches a symlink whose name is innocuous but points
--     into .ssh (`:edit alias` → …/.ssh/config) — the name alone misses
--     it, since Neovim keeps the unresolved name at BufReadPre.
-- fs_realpath is nil for a not-yet-existing BufNewFile, so fall back to
-- the name. Normalize \ to / first so Windows paths (C:\Users\…\.ssh\)
-- match too — the nvim config runs on Windows in this fleet. Set the
-- option on ev.buf explicitly (not vim.opt_local) so protection lands on
-- the file being read even if it isn't the current buffer.
--
-- Watch renames and writes, not just reads: :saveas / :file move an
-- existing (already undofile=true) buffer into ~/.ssh without firing
-- BufReadPre/BufNewFile, which would otherwise write a real undo file for
-- the new sensitive path. BufFilePost catches the rename; BufWritePre is
-- the belt-and-suspenders pass right before any write reaches disk.
local sensitive = require("config.sensitive")
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile", "BufFilePost", "BufWritePre" }, {
  group = augroup,
  callback = function(ev)
    local name = vim.api.nvim_buf_get_name(ev.buf)
    local resolved = (vim.uv or vim.loop).fs_realpath(name) or name
    if sensitive.is_sensitive_undo_path(name) or sensitive.is_sensitive_undo_path(resolved) then
      vim.api.nvim_set_option_value("undofile", false, { buf = ev.buf })
    end
  end,
})

-- Jump to last known cursor position when opening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  command = [[if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif]],
})

-- Remove trailing spaces on save. keeppatterns so the :s doesn't
-- clobber the last search pattern (which `n` and `:%s//x/g` reuse);
-- win{save,rest}view so the cursor doesn't jump to the last stripped
-- line. Skipped where trailing whitespace is meaningful: markdown
-- (two trailing spaces = hard line break), diff/patch (context lines
-- start with a significant space), mail (signature separator "-- ").
local strip_whitespace_excluded = { markdown = true, diff = true, mail = true }
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  pattern = "*",
  callback = function()
    -- Skip special buffers (buftype ~= "") and read-only ones. The :s
    -- below errors E21 on a nomodifiable buffer, and a failing
    -- BufWritePre aborts the whole write — so a protected buffer
    -- couldn't be saved at all. The buftype guard also covers exporting
    -- a scratch/help buffer with `:w file` (e.g. :checkhealth output).
    -- Skip 'binary' buffers too (nvim -b, hex/blob edits): trailing bytes
    -- there are data, not whitespace to trim, and stripping them corrupts
    -- the file.
    if vim.bo.buftype ~= "" or not vim.bo.modifiable or vim.bo.binary then
      return
    end
    if strip_whitespace_excluded[vim.bo.filetype] then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Suppress quickfix/location-list windows from auto-opening (use
-- <leader>qq to browse via fzf-lua instead). buftype "quickfix" covers
-- both kinds, but :cclose only closes the quickfix window — a loclist
-- window would survive it — so close qf-type windows directly instead.
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = augroup,
  callback = function()
    if vim.bo.buftype ~= "quickfix" then
      return
    end
    vim.schedule(function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local wintype = vim.fn.win_gettype(win)
        if wintype == "quickfix" or wintype == "loclist" then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
    end)
  end,
})

-- Terminal/tmux window title: "nvim <focused-buffer-basename>" with
-- long names truncated (first 16 + "…" + last 8) so the prefix
-- (telling you what the file is) gets most of the budget while the
-- extension still shows. Updates on BufEnter/BufFilePost/BufWritePost
-- so it tracks the focused buffer across :e, buffer switches, splits,
-- and renames. Empty/no-name buffers fall back to bare "nvim".
do
  local title_group = vim.api.nvim_create_augroup("user_title", { clear = true })
  local TITLE_MAX, TITLE_HEAD = 25, 16

  -- Neovim glyph prefix (nf-custom-neovim) identifies the title as
  -- nvim — its own dedicated icon, distinct from the gear the zsh
  -- preexec hook puts on other running commands and the folder glyph
  -- on shell-prompt (idle terminal) titles. The glyph replaces the
  -- "nvim" word entirely; the icon already says which tool this is.
  local TITLE_PREFIX = " "

  local function title_for_buf()
    -- Strip control chars from the basename before it flows into
    -- 'titlestring' and the TermClose OSC-2 write below. A filename may
    -- legally contain ESC/BEL bytes (any byte but / and NUL); left in,
    -- they'd be emitted raw in the terminal title sequence — a BEL ends
    -- the OSC early, so trailing bytes execute as terminal commands
    -- (escape injection from a maliciously-named file). Strip first so
    -- the cleaned width, not the raw width, drives truncation below.
    local name = (vim.fn.expand("%:t"):gsub("%c", ""))
    if name == "" then
      return vim.trim(TITLE_PREFIX)
    end
    if vim.fn.strchars(name) > TITLE_MAX then
      local tail = TITLE_MAX - TITLE_HEAD - 1
      name = vim.fn.strcharpart(name, 0, TITLE_HEAD) .. "…" .. vim.fn.strcharpart(name, vim.fn.strchars(name) - tail)
    end
    return TITLE_PREFIX .. name
  end

  vim.opt.title = true
  local function update_title()
    -- Escape `%` because vim parses titlestring as a format string.
    vim.opt.titlestring = (title_for_buf():gsub("%%", "%%%%"))
  end
  -- vim.schedule defers to the main loop so rapid-fire events
  -- (e.g. fzf-lua picker close → window switch → file edit) settle
  -- before we read `%:t`. WinEnter / BufWinEnter cover cases where
  -- `BufEnter` is suppressed (fzf-lua opens with `noautocmd edit`,
  -- etc.) by re-checking on window/buffer-window transitions.
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufFilePost", "BufWritePost", "WinEnter" }, {
    group = title_group,
    callback = function()
      vim.schedule(update_title)
    end,
  })

  -- A TUI run inside a :terminal (lazygit) sets the wezterm tab title
  -- itself with an OSC escape. Neovim only re-sends 'titlestring' to the
  -- host terminal when the string *changes*; closing the float lands us
  -- back on the same buffer, so the string is unchanged, Neovim stays
  -- silent, and the tab is left showing the program's title. On
  -- TermClose, write the current title to the host terminal directly
  -- (OSC 2) so it overwrites whatever the exited program left behind —
  -- snacks.nvim pushes OSC the same way for its lazygit theme colors.
  vim.api.nvim_create_autocmd("TermClose", {
    group = title_group,
    callback = function()
      vim.schedule(function()
        pcall(function()
          io.write("\27]2;" .. title_for_buf() .. "\7")
          io.flush()
        end)
      end)
    end,
  })

  update_title()
end
