-- Fuzzy finder
return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "FzfLua",
  keys = {
    { "<leader>ff", function() require("fzf-lua").files() end,                 desc = "Find files" },
    { "<leader>fg", function() require("fzf-lua").grep_project() end,          desc = "Fuzzy search project" },
    { "<leader>fb", function() require("fzf-lua").lines() end,                 desc = "Fuzzy search buffer" },
    { "<leader>fr", function() require("fzf-lua").oldfiles() end,              desc = "Recent files" },
    { "<leader>fs", function() require("fzf-lua").lsp_document_symbols() end,  desc = "Document symbols" },
    { "<leader>fS", function() require("fzf-lua").lsp_workspace_symbols() end, desc = "Workspace symbols" },
    { "<leader>fj", function() require("fzf-lua").jumps() end,                 desc = "Jumplist" },
    { "<leader>fm", function() require("fzf-lua").marks() end,                 desc = "Marks" },
    { "<leader>cD", function() require("fzf-lua").diagnostics_workspace() end, desc = "Workspace diagnostics" },
    { "<leader>qq", function() require("fzf-lua").quickfix() end,              desc = "Quickfix list" },
    { "<leader>qh", function() require("fzf-lua").quickfix_stack() end,        desc = "Quickfix history" },
    { "<leader>qa", function()
        vim.fn.setqflist({}, "a", {
          title = "Bookmarks",
          items = { {
            filename = vim.fn.expand("%"),
            lnum = vim.fn.line("."),
            col = vim.fn.col("."),
            text = vim.fn.getline("."),
          } },
        })
        vim.notify("Added to quickfix", vim.log.levels.INFO)
      end, desc = "Add line to quickfix" },
    { "<leader>?", function() require("fzf-lua").keymaps() end,                desc = "Search keymaps" },
  },
  config = function()
    local fzf = require("fzf-lua")
    fzf.setup({
      actions = {
        files = {
          true,
          ["ctrl-]"] = fzf.actions.file_vsplit,
        },
      },
      diagnostics = {
        diag_source = true,
      },
    })
  end,
}
