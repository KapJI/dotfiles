-- File explorer. Eager-loaded so it replaces netrw when nvim opens a
-- directory directly (e.g. `nvim .`); the `-` key still works to open
-- the parent directory of the current buffer.
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  keys = {
    { "-", "<Cmd>Oil<CR>", silent = true, desc = "Open file explorer" },
  },
  opts = {
    default_file_explorer = true, -- replaces netrw on directory open
    view_options = { show_hidden = true },
    skip_confirm_for_simple_edits = true,
  },
}
