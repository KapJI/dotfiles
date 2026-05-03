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
                direction            = "right",
                minimap_width        = 16,
                fix_width            = true,           -- not affected by <C-w>=
                close_if_last_window = true,
            },

            -- Skip minimap on UI / scratch buffers.
            exclude_filetypes = {
                "help", "alpha", "snacks_dashboard", "oil",
                "fzf", "TelescopePrompt", "lazy", "mason",
                "undotree", "diff",
            },
            exclude_buftypes = {
                "nofile", "nowrite", "quickfix", "terminal", "prompt", "help",
            },

            -- Slightly less aggressive refresh than default 200ms.
            delay = 300,

            -- Render: treesitter syntax + duplicate of satellite's mark
            -- layers. Slight redundancy with satellite is intentional —
            -- minimap shows spatial *shape* of the file, satellite shows
            -- the right-edge bar; both are useful at-a-glance.
            treesitter = { enabled = true },
            diagnostic = { enabled = true },
            git        = { enabled = true },
            search     = { enabled = true },
            mark       = { enabled = false },   -- letter marks, low value at this scale
            lsp        = { enabled = false },   -- semantic tokens, mostly invisible at this scale

            -- Mouse click on minimap → jump cursor in main buffer.
            -- auto_switch_focus = false: cursor moves but focus stays in main.
            click = { enabled = true, auto_switch_focus = false },

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
