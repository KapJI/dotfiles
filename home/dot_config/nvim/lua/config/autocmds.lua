-- Autocommands not specific to any plugin.

-- Jump to last known cursor position when opening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  command = [[if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif]],
})

-- Remove trailing spaces on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- Suppress quickfix window from auto-opening (use <leader>qq to browse via fzf-lua instead)
vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function()
    if vim.bo.buftype == "quickfix" then
      vim.schedule(function() vim.cmd("cclose") end)
    end
  end,
})

-- Terminal/tmux window title: "nvim <focused-buffer-basename>" with
-- long names truncated (first 16 + "…" + last 8) so the prefix
-- (telling you what the file is) gets most of the budget while the
-- extension still shows. Updates on BufEnter/BufFilePost/BufWritePost
-- so it tracks the focused buffer across :e, buffer switches, splits,
-- and renames. Empty/no-name buffers fall back to bare "nvim".
do
  local TITLE_MAX, TITLE_HEAD = 25, 16

  -- Neovim glyph prefix (nf-custom-neovim) identifies the title as
  -- nvim — its own dedicated icon, distinct from the gear the zsh
  -- preexec hook puts on other running commands and the folder glyph
  -- on shell-prompt (idle terminal) titles. The glyph replaces the
  -- "nvim" word entirely; the icon already says which tool this is.
  local TITLE_PREFIX = " "

  local function title_for_buf()
    local name = vim.fn.expand("%:t")
    if name == "" then return vim.trim(TITLE_PREFIX) end
    if vim.fn.strchars(name) > TITLE_MAX then
      local tail = TITLE_MAX - TITLE_HEAD - 1
      name = vim.fn.strcharpart(name, 0, TITLE_HEAD)
        .. "…"
        .. vim.fn.strcharpart(name, vim.fn.strchars(name) - tail)
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
  vim.api.nvim_create_autocmd(
    { "BufEnter", "BufWinEnter", "BufFilePost", "BufWritePost", "WinEnter" },
    { callback = function() vim.schedule(update_title) end }
  )

  -- A TUI run inside a :terminal (lazygit) sets the wezterm tab title
  -- itself with an OSC escape. Neovim only re-sends 'titlestring' to the
  -- host terminal when the string *changes*; closing the float lands us
  -- back on the same buffer, so the string is unchanged, Neovim stays
  -- silent, and the tab is left showing the program's title. On
  -- TermClose, write the current title to the host terminal directly
  -- (OSC 2) so it overwrites whatever the exited program left behind —
  -- snacks.nvim pushes OSC the same way for its lazygit theme colors.
  vim.api.nvim_create_autocmd("TermClose", {
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
