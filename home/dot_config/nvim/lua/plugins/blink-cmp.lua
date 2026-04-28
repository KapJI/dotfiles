-- Completion engine
return {
  "saghen/blink.cmp",
  version = "*",                -- use prebuilt rust binary from latest release
  event = "InsertEnter",
  dependencies = { "L3MON4D3/LuaSnip" },
  opts = {
    keymap = {
      preset = "default",
      ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-j>"] = { "snippet_forward", "fallback" },
      ["<C-k>"] = { "snippet_backward", "fallback" },
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
  },
}
