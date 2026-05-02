-- todo-comments.nvim: highlight TODO / FIX / HACK / NOTE / PERF / WARN / TEST
-- comments with colored signs + provide commands to list them across the project.
--
-- Defaults are sensible (keyword set, colors, icons via Nerd Font), so just
-- wire keys and let the plugin do its thing.
return {
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TodoFzfLua", "TodoQuickFix", "TodoLocList" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ct", "<Cmd>TodoFzfLua<CR>",                            desc = "List TODOs (project)" },
      { "]t",         function() require("todo-comments").jump_next() end, desc = "Next TODO comment" },
      { "[t",         function() require("todo-comments").jump_prev() end, desc = "Previous TODO comment" },
    },
    opts = {
      signs = true, -- gutter sign for each TODO line
    },
  },
}
