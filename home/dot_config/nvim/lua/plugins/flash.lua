-- Jump to any position with search labels
return {
  "folke/flash.nvim",
  event = "VeryLazy",
  config = function()
    local flash = require("flash")
    flash.setup({
      modes = {
        -- f/F/t/T use flash's enhanced char motion (multi-line search,
        -- clever-f repeat). Drop the backdrop entirely: dimming the
        -- screen for a local motion is noise, it lingered as a
        -- pseudo-mode, and clearing it per jump (autohide) made each `;`
        -- repeat tear it down and rebuild it — a blink. Match highlights
        -- still show. flash's own `search` mode disables it the same way.
        char = { highlight = { backdrop = false } },
      },
    })
    local keyset = vim.keymap.set
    keyset({ "n", "x" }, "s", flash.jump, { desc = "Flash jump" })
    -- Normal mode only: visual-mode `S` stays with nvim-surround
    -- (wrap a selection). flash.treesitter is a normal-mode starter
    -- anyway, and visual mode keeps `R` (flash.treesitter_search).
    keyset("n", "S", flash.treesitter, { desc = "Flash treesitter select" })
    keyset("o", "r", flash.remote, { desc = "Flash remote" })
    keyset({ "o", "x" }, "R", flash.treesitter_search, { desc = "Flash treesitter search" })
    keyset("c", "<C-s>", flash.toggle, { desc = "Toggle flash search" })
  end,
}
