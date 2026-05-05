-- neominimap.nvim — Sublime-Text-style minimap with treesitter-colored
-- rendering. Mark layers (diagnostic/git/search/marks) are disabled to
-- avoid duplicating what satellite.nvim already shows on the right edge;
-- the value here is the visual *shape* of the file.
--
-- Layout = "float": minimap is a translucent overlay on the right edge
-- of the source window, NOT a separate split. This avoids a class of
-- data-loss bugs that split layout has when it becomes the last window
-- (upstream's close_if_last_window cascades into a forced `:qa!`).
return {
    "Isrothy/neominimap.nvim",
    version = "v3.x.x",
    enabled = true,
    lazy    = false, -- per upstream guidance
    init    = function()
        -- Configuration must be set on vim.g before the plugin loads (mini-style).
        vim.g.neominimap = {
            auto_enable       = true,
            layout            = "float",
            float             = {
                minimap_width      = 16,
                max_minimap_height = nil, -- match source window height
            },

            -- Skip minimap on UI / scratch buffers and on big files
            -- (snacks.bigfile remaps oversized buffers to filetype "bigfile").
            exclude_filetypes = {
                "help", "alpha", "snacks_dashboard", "oil",
                "fzf", "TelescopePrompt", "lazy", "mason",
                "undotree", "diff", "bigfile",
            },
            exclude_buftypes  = {
                "nofile", "nowrite", "quickfix", "terminal", "prompt", "help",
            },

            -- Slightly less aggressive refresh than default 200ms.
            delay             = 300,

            -- Render: treesitter syntax + duplicate of satellite's mark
            -- layers. Slight redundancy with satellite is intentional —
            -- minimap shows spatial *shape* of the file, satellite shows
            -- the right-edge bar; both are useful at-a-glance.
            treesitter        = { enabled = true },
            diagnostic        = { enabled = true },
            git               = { enabled = true },
            search            = { enabled = true },
            mark              = { enabled = false }, -- letter marks, low value at this scale
            lsp               = { enabled = false }, -- semantic tokens, mostly invisible at this scale

            -- Click on minimap moves the source cursor; auto_switch_focus
            -- = false makes upstream bounce focus back to the source window
            -- automatically (float-layout-only feature; works natively here).
            click             = { enabled = true, auto_switch_focus = false },

            -- Slight transparency so the overlay doesn't feel like a wall
            -- over the right edge of the buffer.
            winopt            = function(opt, _)
                opt.winblend = 30
            end,
        }

        -- Hide the minimap while the snacks dashboard is shown — the
        -- startup [No Name] buffer auto-enables minimap before snacks
        -- takes over and sets filetype=snacks_dashboard, leaving a stale
        -- overlay. snacks.dashboard fires User SnacksDashboard{Opened,
        -- Closed} which we bracket here.
        local dash_group = vim.api.nvim_create_augroup("user_neominimap_dashboard", { clear = true })
        vim.api.nvim_create_autocmd("User", {
            group = dash_group,
            pattern = "SnacksDashboardOpened",
            callback = function()
                vim.schedule(function() pcall(vim.cmd, "Neominimap Disable") end)
            end,
        })
        vim.api.nvim_create_autocmd("User", {
            group = dash_group,
            pattern = "SnacksDashboardClosed",
            callback = function()
                vim.schedule(function() pcall(vim.cmd, "Neominimap Enable") end)
            end,
        })
    end,
    keys    = {
        { "<leader>nm", "<Cmd>Neominimap Toggle<CR>", desc = "Toggle minimap" },
    },
}
