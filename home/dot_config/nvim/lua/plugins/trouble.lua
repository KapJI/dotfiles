-- folke/trouble.nvim — browse-style UI for diagnostics, LSP refs,
-- quickfix, and location list. Complements fzf-lua's search-style
-- diagnostics: trouble is "all issues across the project, browse them",
-- fzf-lua is "find one specific thing". Both have their niche.
--
-- Lives under <leader>X (capital) to avoid colliding with <leader>x
-- (eXchange/swap, used by treesitter-textobjects) and the
-- <leader>qq fzf-lua quickfix mapping.
return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  opts = {},
  keys = {
    { "<leader>Xx", "<cmd>Trouble diagnostics toggle<cr>",                        desc = "Workspace diagnostics" },
    { "<leader>XX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",           desc = "Buffer diagnostics" },
    { "<leader>Xs", "<cmd>Trouble symbols toggle focus=false<cr>",                desc = "Symbols" },
    { "<leader>Xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP refs/defs" },
    { "<leader>XL", "<cmd>Trouble loclist toggle<cr>",                            desc = "Location list" },
    { "<leader>XQ", "<cmd>Trouble qflist toggle<cr>",                             desc = "Quickfix list" },
  },
}
