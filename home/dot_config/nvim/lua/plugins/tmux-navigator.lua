-- Switch between splits/tmux panes with Alt+hjkl
return {
  "christoomey/vim-tmux-navigator",
  cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight", "TmuxNavigatePrevious" },
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  keys = {
    { "<M-h>", ":TmuxNavigateLeft<CR>",  silent = true, desc = "Navigate left" },
    { "<M-j>", ":TmuxNavigateDown<CR>",  silent = true, desc = "Navigate down" },
    { "<M-k>", ":TmuxNavigateUp<CR>",    silent = true, desc = "Navigate up" },
    { "<M-l>", ":TmuxNavigateRight<CR>", silent = true, desc = "Navigate right" },
  },
}
