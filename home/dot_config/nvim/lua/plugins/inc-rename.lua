-- inc-rename.nvim: LSP rename with live preview as you type. Built on nvim's
-- :command-preview feature; uses the same textDocument/rename LSP method as
-- vim.lsp.buf.rename — just renders a preview of every change before commit.
return {
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    keys = {
      {
        "<leader>cr",
        function() return ":IncRename " .. vim.fn.expand("<cword>") end,
        expr = true, -- the keymap returns the command string with cword pre-filled
        desc = "Rename symbol (LSP, with preview)",
      },
    },
    opts = {},
  },
}
