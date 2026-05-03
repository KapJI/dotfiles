-- Visual undo tree. Navigates persistent-undo branches by *seeing* them
-- (with timestamps + diff preview) instead of blindly stepping through
-- chronologically. Replaces the role mini.bracketed.undo would have played.
return {
    "mbbill/undotree",
    cmd  = "UndotreeToggle",
    keys = {
        { "<leader>u", "<Cmd>UndotreeToggle<CR>", desc = "Undo tree" },
    },
    init = function()
        -- Layout with diff preview at the bottom (style 2 of 4 built-in layouts).
        vim.g.undotree_WindowLayout         = 2
        -- Move cursor into the undotree window on toggle.
        vim.g.undotree_SetFocusWhenToggle   = 1
        -- Highlight text that differs from current state.
        vim.g.undotree_HighlightChangedText = 1
        -- Width of the tree pane (default 30). +5 for breathing room.
        vim.g.undotree_SplitWidth           = 35
        -- Auto-open the diff panel; live-update it as the cursor moves on j/k.
        vim.g.undotree_DiffAutoOpen         = 1
    end,
}
