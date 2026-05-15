-- Completion engine
return {
  "saghen/blink.cmp",
  version = "*",                -- use prebuilt rust binary from latest release
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = { "L3MON4D3/LuaSnip" },
  opts = {
    keymap = {
      preset = "enter",
      ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-j>"] = { "snippet_forward", "fallback" },
      ["<C-k>"] = { "snippet_backward", "fallback" },
      -- Tab is context-sensitive:
      --   menu visible      → cycle to next item
      --   after a word char → open menu (request completion)
      --   col 0 or after whitespace → real tab (so indentation works)
      ["<Tab>"] = {
        function(cmp)
          if cmp.is_visible() then return cmp.select_next() end
          local col = vim.fn.col(".") - 1
          if col > 0 and not vim.fn.getline("."):sub(col, col):match("%s") then
            return cmp.show()
          end
        end,
        "fallback",
      },
      ["<S-Tab>"] = { "select_prev", "fallback" },
    },
    snippets = { preset = "luasnip" },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    completion = {
      menu = {
        scrollbar = true,
        draw = {
          treesitter = { "lsp" },
        },
      },
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      ghost_text = { enabled = true },
    },
    cmdline = {
      keymap = {
        preset = "cmdline",
        -- Tab when menu hidden: open it — but if there's exactly one
        -- match, `show_and_insert_or_accept_single` accepts it outright
        -- instead of showing a one-item menu. Subsequent Tab/S-Tab
        -- cycle without overwriting the typed prefix (auto_insert=false).
        -- Commit a selected item with C-y.
        ["<Tab>"] = { "show_and_insert_or_accept_single", "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
      },
      completion = {
        list = { selection = { preselect = true, auto_insert = false } },
      },
    },
  },
}
