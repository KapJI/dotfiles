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
                "help", "alpha", "snacks_dashboard",
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

        -- Per-window sidescrolloff: keep cursor 1 col left of the minimap
        -- overlay (16 cols on the right) so it never disappears under it
        -- on long lines. Set window-local — windows without a minimap
        -- attached keep the global sidescrolloff = 1 (see options.lua).
        local DEFAULT_SSO = 1   -- matches vim.opt.sidescrolloff
        local MINIMAP_SSO = 17  -- minimap_width (16) + 1 col gap

        local function refresh_window(winid)
            if not vim.api.nvim_win_is_valid(winid) then return end
            local buf = vim.api.nvim_win_get_buf(winid)
            if vim.bo[buf].filetype == "neominimap" then return end
            local ok, window_map = pcall(require, "neominimap.window.float.window_map")
            if not ok then return end
            local mwinid = window_map.get_minimap_winid(winid)
            local has = mwinid ~= nil and vim.api.nvim_win_is_valid(mwinid)
            vim.api.nvim_set_option_value("sidescrolloff",
                has and MINIMAP_SSO or DEFAULT_SSO,
                { scope = "local", win = winid })
        end

        local function refresh_all()
            for _, winid in ipairs(vim.api.nvim_list_wins()) do
                refresh_window(winid)
            end
        end

        -- Hook on raw window events. Minimap creation/destruction always
        -- shows up as WinNew/WinClosed (the float is a real window with
        -- filetype=neominimap); user navigation shows up as WinEnter.
        -- defer_fn waits past neominimap's chained vim.schedule callbacks
        -- so window_map sees the post-update state.
        --
        -- Avoid: noice's `User MinimapBufferCreated` events. Those are
        -- emitted with `group = "Neominimap"`, which restricts firing to
        -- autocmds inside that group — registering there would step on
        -- neominimap's private augroup.
        local sso_group = vim.api.nvim_create_augroup("user_neominimap_sidescrolloff", { clear = true })
        vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "WinNew", "WinClosed" }, {
            group = sso_group,
            callback = function() vim.defer_fn(refresh_all, 30) end,
        })

        -- Initial pass once nvim is fully loaded — covers the very first
        -- window which may not fire a fresh WinEnter.
        vim.api.nvim_create_autocmd("VimEnter", {
            group = sso_group,
            once  = true,
            callback = function() vim.defer_fn(refresh_all, 50) end,
        })
    end,
    keys    = {
        { "<leader>nm", "<Cmd>Neominimap Toggle<CR>", desc = "Toggle minimap" },
    },
}
