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
      -- Tab when menu hidden: open it (more useful than literal tab in
      -- editing contexts). When visible: cycle. Falls through to a real
      -- tab character only if blink has nothing to show.
      ["<Tab>"] = { "show", "select_next", "fallback" },
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
        -- Match insert-mode behavior: Tab when menu hidden opens it
        -- (cmdline auto-show usually beats us to it, but covers the
        -- bare-`:` case). Subsequent Tab/S-Tab cycle without overwriting
        -- the typed prefix (auto_insert=false). Commit with C-y.
        ["<Tab>"] = { "show", "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
      },
      completion = {
        list = { selection = { preselect = true, auto_insert = false } },
      },
    },
  },
}
