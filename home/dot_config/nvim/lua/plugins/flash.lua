-- Jump to any position with search labels
return {
  "folke/flash.nvim",
  event = "VeryLazy",
  config = function()
    local flash = require("flash")
    flash.setup()
    local keyset = vim.keymap.set
    keyset({ "n", "x" }, "s", flash.jump, { desc = "Flash jump" })
    keyset({ "n", "x" }, "S", flash.treesitter, { desc = "Flash treesitter select" })
    keyset("o", "r", flash.remote, { desc = "Flash remote" })
    keyset({ "o", "x" }, "R", flash.treesitter_search, { desc = "Flash treesitter search" })
    keyset("c", "<C-s>", flash.toggle, { desc = "Toggle flash search" })
  end,
}
