-- lazydev.nvim — lua_ls workspace configuration for nvim-config editing.
-- Adds only the modules a buffer actually require()s to the workspace
-- library (plus the nvim runtime), instead of the old approach of
-- passing every runtimepath dir via workspace.library — which made
-- lua_ls index all ~50 plugins on every start.
return {
  "folke/lazydev.nvim",
  ft = "lua", -- only when editing lua
  opts = {
    library = {
      -- Load luv (vim.uv) types when a buffer mentions vim.uv.
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    },
  },
}
