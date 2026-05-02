-- statuscol.nvim: customize the leftmost column (folds + signs + line numbers).
-- Merges gitsigns / diagnostic / mark signs into a single 1-char column instead
-- of stacking them, reclaiming 2-3 chars of horizontal space per buffer.
return {
  {
    "luukvbaal/statuscol.nvim",
    event = "VeryLazy",
    config = function()
      local builtin = require("statuscol.builtin")
      require("statuscol").setup({
        relculright = true, -- right-align relative line numbers
        segments = {
          -- 1. Fold column (click to toggle the fold under cursor)
          { text = { builtin.foldfunc }, click = "v:lua.ScFa" },

          -- 2. Signs (all namespaces merged into one column).
          --    auto = true → segment vanishes when no signs on the line.
          {
            sign = { namespace = { ".*" }, maxwidth = 1, colwidth = 1, auto = true },
            click = "v:lua.ScSa",
          },

          -- 3. Line numbers — no click handler so vim's default mouse
          --    behavior wins (single click moves cursor to that line).
          { text = { builtin.lnumfunc, " " } },
        },
      })
    end,
  },
}
