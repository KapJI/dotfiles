-- neominimap.nvim — Sublime-Text-style minimap with treesitter-colored
-- rendering. Mark layers (diagnostic/git/search/marks) are disabled to
-- avoid duplicating what satellite.nvim already shows on the right edge;
-- the value here is the visual *shape* of the file.
return {
    "Isrothy/neominimap.nvim",
    version  = "v3.x.x",
    enabled  = true,
    lazy     = false,        -- per upstream guidance
    init     = function()
        -- Configuration must be set on vim.g before the plugin loads (mini-style).
        vim.g.neominimap = {
            auto_enable = true,
            layout      = "split",
            split = {
                direction = "right",
                width     = 16,
                close_if_last_window = true,   -- don't keep just the minimap open
            },

            -- Render: treesitter syntax highlighting in the minimap.
            treesitter = { enabled = true },

            -- Mark layers — DISABLED. satellite.nvim already shows these on
            -- the buffer's right edge; rendering them on the minimap too
            -- would be redundant and visually noisy.
            diagnostic = { enabled = false },
            git        = { enabled = false },
            search     = { enabled = false },
            mark       = { enabled = false },
            lsp        = { enabled = false },

            -- Slight transparency so the panel doesn't feel like a wall.
            winopt = function(opt, _)
                opt.winblend = 30
            end,
        }
    end,
    keys = {
        { "<leader>nm", "<Cmd>Neominimap Toggle<CR>", desc = "Toggle minimap" },
    },
}
