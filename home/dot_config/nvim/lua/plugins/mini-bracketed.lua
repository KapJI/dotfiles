-- Unified ]<key> / [<key> navigation across many targets.
-- Coexists with marks.nvim (which gets ]m/[m via its own setup), gitsigns
-- (]c/[c), todo-comments (]t/[t), and treesitter-textobjects (]f/[f);
-- collisions are disabled below by setting suffix = ''.
return {
    "echasnovski/mini.bracketed",
    event = "BufReadPost",
    opts = {
        buffer     = { suffix = "b", options = {} },  -- ]b/[b: cycle buffers
        diagnostic = { suffix = "d", options = {} },  -- ]d/[d: replaces our old ]g/[g
        indent     = { suffix = "i", options = {} },  -- ]i/[i: same-indent line
        oldfile    = { suffix = "o", options = {} },  -- ]o/[o: recent files
        quickfix   = { suffix = "q", options = {} },  -- ]q/[q: quickfix entries
        -- undo: disabled — undotree (<leader>u) is a better undo-history UX.
        yank       = { suffix = "y", options = {} },  -- ]y/[y: walk yank history

        -- Disabled (collisions or duplicates of existing keymaps):
        comment    = { suffix = "" },  -- gitsigns owns ]c/[c
        conflict   = { suffix = "" },  -- treesitter-context owns [x
        file       = { suffix = "" },  -- treesitter-textobjects owns ]f/[f
        treesitter = { suffix = "" },  -- todo-comments owns ]t/[t
        jump       = { suffix = "" },  -- vim's <C-o>/<C-i> already covers
        undo       = { suffix = "" },  -- undotree (<leader>u) replaces this
        location   = { suffix = "" },  -- not used in our workflow
        window     = { suffix = "" },  -- smart-splits <M-hjkl> covers
    },
}
