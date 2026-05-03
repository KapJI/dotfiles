-- noice.nvim — used here as a single-feature plugin: the cmdline_popup
-- view replaces nvim's bottom-row `:` and `/` UI with a centered floating
-- window. Everything else (notify, messages, popupmenu, lsp.* floats) is
-- explicitly disabled so we don't duplicate snacks.notifier or contend
-- with blink.cmp's completion menu.
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    cmdline = {
      enabled = true,
      view    = "cmdline_popup",
    },
    messages   = { enabled = false },  -- snacks.notifier owns these
    popupmenu  = { enabled = false },  -- blink.cmp / vim's wildmenu
    notify     = { enabled = false },  -- snacks.notifier
    lsp = {
      progress  = { enabled = false },
      hover     = { enabled = false },
      signature = { enabled = false },
    },
    presets = {
      command_palette       = true,    -- cmdline + popupmenu in one centered panel
      long_message_to_split = true,    -- :messages in a split, not a tiny float
    },
  },
}
