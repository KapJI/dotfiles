-- Autocommands not specific to any plugin. Grouped under a named augroup
-- (cleared on re-source) so re-running this file — e.g. `:luafile %` while
-- editing config — replaces the handlers instead of stacking duplicates.
local augroup = vim.api.nvim_create_augroup("user_autocmds", { clear = true })

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
    if vim.bo.buftype ~= "" or not vim.bo.modifiable then
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
    local name = vim.fn.expand("%:t")
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
