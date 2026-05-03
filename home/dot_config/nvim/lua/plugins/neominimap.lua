-- neominimap.nvim — Sublime-Text-style minimap with treesitter-colored
-- rendering. Mark layers (diagnostic/git/search/marks) are disabled to
-- avoid duplicating what satellite.nvim already shows on the right edge;
-- the value here is the visual *shape* of the file.
return {
    "Isrothy/neominimap.nvim",
    version = "v3.x.x",
    enabled = true,
    lazy    = false,  -- per upstream guidance
    init    = function()
        -- Configuration must be set on vim.g before the plugin loads (mini-style).
        vim.g.neominimap = {
            auto_enable       = true,
            layout            = "split",
            split             = {
                direction            = "right",
                minimap_width        = 16,
                fix_width            = true, -- not affected by <C-w>=
                close_if_last_window = true,
            },

            -- Skip minimap on UI / scratch buffers.
            exclude_filetypes = {
                "help", "alpha", "snacks_dashboard", "oil",
                "fzf", "TelescopePrompt", "lazy", "mason",
                "undotree", "diff",
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

            -- Mouse click on minimap → jump cursor in main buffer.
            -- NOTE: `auto_switch_focus` is only honored in the FLOAT layout
            -- (see lua/neominimap/window/float/init.lua); for split layout
            -- it's a no-op. The bounce-focus-back behavior is implemented
            -- by the WinEnter autocmd registered below. Value here matches
            -- intent ("don't keep focus on minimap") even though ignored.
            click             = { enabled = true, auto_switch_focus = false },

            -- Slight transparency so the panel doesn't feel like a wall.
            winopt            = function(opt, _)
                opt.winblend = 30
            end,
        }

        -- Split-layout click → bounce focus back to source window.
        -- Upstream's `click.auto_switch_focus` is only wired in the float
        -- layout, so we replicate the bounce here. The minimap's CursorMoved
        -- handler still fires first (it runs synchronously on entering the
        -- window and moves the source cursor); we then schedule a return to
        -- the previous window so navigation keys land in the editor again.
        vim.api.nvim_create_autocmd("WinEnter", {
            group = vim.api.nvim_create_augroup("user_neominimap_bounce", { clear = true }),
            callback = function()
                if vim.bo.filetype ~= "neominimap" then return end
                local prev = vim.fn.win_getid(vim.fn.winnr("#"))
                if prev == 0 or prev == vim.api.nvim_get_current_win() then return end
                vim.schedule(function()
                    if vim.bo.filetype == "neominimap"
                        and vim.api.nvim_win_is_valid(prev)
                    then
                        vim.api.nvim_set_current_win(prev)
                    end
                end)
            end,
        })
    end,
    keys    = {
        { "<leader>nm", "<Cmd>Neominimap Toggle<CR>", desc = "Toggle minimap" },
    },
}
