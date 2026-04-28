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
