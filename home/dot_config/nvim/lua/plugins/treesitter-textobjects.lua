-- Treesitter-aware text-objects: language-semantic versions of vim's iw/ip/i(.
--
-- Bindings:
--   af / if   around / inner function
--   ac / ic   around / inner class
--   aa / ia   around / inner argument (parameter)
--   ab / ib   around / inner block (if/for/while/try body)
--             ↳ shadows vim's `ab`/`ib` (parens) — use i(/a( for those instead
--   ]f / [f   next / prev function start  (class movement omitted to avoid
--             collision with gitsigns ]c/[c)
--   <leader>xa / <leader>xA   eXchange Argument with next / prev neighbor
--                              (group: <leader>x for swap/exchange ops)
return {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "BufReadPost",
    config = function()
        local sel  = require("nvim-treesitter-textobjects.select")
        local move = require("nvim-treesitter-textobjects.move")
        local swap = require("nvim-treesitter-textobjects.swap")
        local k    = vim.keymap.set
        local xo   = { "x", "o" }
        local nxo  = { "n", "x", "o" }

        -- Text objects
        k(xo, "af", function() sel.select_textobject("@function.outer",  "textobjects") end, { desc = "around function" })
        k(xo, "if", function() sel.select_textobject("@function.inner",  "textobjects") end, { desc = "inner function"  })
        k(xo, "ac", function() sel.select_textobject("@class.outer",     "textobjects") end, { desc = "around class"    })
        k(xo, "ic", function() sel.select_textobject("@class.inner",     "textobjects") end, { desc = "inner class"     })
        k(xo, "aa", function() sel.select_textobject("@parameter.outer", "textobjects") end, { desc = "around argument" })
        k(xo, "ia", function() sel.select_textobject("@parameter.inner", "textobjects") end, { desc = "inner argument"  })
        k(xo, "ab", function() sel.select_textobject("@block.outer",     "textobjects") end, { desc = "around block"    })
        k(xo, "ib", function() sel.select_textobject("@block.inner",     "textobjects") end, { desc = "inner block"     })

        -- Function-start movement
        k(nxo, "]f", function() move.goto_next_start("@function.outer",     "textobjects") end, { desc = "next function start" })
        k(nxo, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "prev function start" })

        -- Argument swap
        k("n", "<leader>xa", function() swap.swap_next("@parameter.inner")     end, { desc = "swap argument with next" })
        k("n", "<leader>xA", function() swap.swap_previous("@parameter.inner") end, { desc = "swap argument with prev" })
    end,
}
