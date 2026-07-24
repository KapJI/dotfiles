-- Fuzzy finder
return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "FzfLua",
  keys = {
    {
      "<leader>ff",
      function()
        require("fzf-lua").files()
      end,
      desc = "Find files",
    },
    {
      "<leader>fg",
      function()
        require("fzf-lua").grep_project()
      end,
      desc = "Fuzzy search project",
    },
    {
      "<leader>fb",
      function()
        require("fzf-lua").blines()
      end,
      desc = "Fuzzy search buffer",
    },
    {
      "<leader>fr",
      function()
        require("fzf-lua").oldfiles()
      end,
      desc = "Recent files",
    },
    {
      "<leader>fs",
      function()
        require("fzf-lua").lsp_document_symbols()
      end,
      desc = "Document symbols",
    },
    {
      "<leader>fS",
      function()
        require("fzf-lua").lsp_live_workspace_symbols()
      end,
      desc = "Workspace symbols (live)",
    },
    {
      "<leader>fj",
      function()
        require("fzf-lua").jumps()
      end,
      desc = "Jumplist",
    },
    {
      "<leader>fm",
      function()
        require("fzf-lua").marks()
      end,
      desc = "Marks",
    },
    {
      "<leader>fh",
      function()
        require("fzf-lua").helptags()
      end,
      desc = "Help tags (nvim docs)",
    },
    {
      "<leader>fM",
      function()
        require("fzf-lua").manpages()
      end,
      desc = "Man pages",
    },
    {
      "<leader>fc",
      function()
        require("fzf-lua").commands()
      end,
      desc = "Nvim commands",
    },
    {
      "<leader>cD",
      function()
        require("fzf-lua").diagnostics_workspace()
      end,
      desc = "Workspace diagnostics",
    },
    {
      "<leader>qq",
      function()
        require("fzf-lua").quickfix()
      end,
      desc = "Quickfix list",
    },
    {
      "<leader>qh",
      function()
        require("fzf-lua").quickfix_stack()
      end,
      desc = "Quickfix history",
    },
    {
      "<leader>qa",
      function()
        -- Append to a dedicated "Bookmarks" list. setqflist(_, "a", …)
        -- appends to whatever list is CURRENT — which would clobber an
        -- active Diagnostics/grep list and retitle it "Bookmarks". So
        -- append only when the current list is already Bookmarks;
        -- otherwise start a fresh list with action " ".
        local action = vim.fn.getqflist({ title = 0 }).title == "Bookmarks" and "a" or " "
        vim.fn.setqflist({}, action, {
          title = "Bookmarks",
          items = {
            {
              filename = vim.fn.expand("%"),
              lnum = vim.fn.line("."),
              col = vim.fn.col("."),
              text = vim.fn.getline("."),
            },
          },
        })
        vim.notify("Added to bookmarks", vim.log.levels.INFO)
      end,
      desc = "Add line to bookmarks (quickfix)",
    },
    {
      "<leader>?",
      function()
        require("fzf-lua").keymaps()
      end,
      desc = "Search keymaps",
    },
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
