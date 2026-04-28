-- Catppuccin colorscheme
return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,            -- load before any other plugin so highlights exist
  config = function()
    require("catppuccin").setup({
      integrations = {
        diffview = true,
        nvim_surround = true,
        which_key = true,
      },
    })
    vim.cmd.colorscheme("catppuccin-mocha")
  end,
}
