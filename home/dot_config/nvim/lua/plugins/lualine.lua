-- Statusline
return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim" },
  event = "VeryLazy",
  config = function()
    local inactive_lualine_bg = "#1e1e31"
    local lualine_theme = require("lualine.themes.catppuccin-mocha")
    lualine_theme.inactive.c.bg = inactive_lualine_bg
    require("lualine").setup({
      options = {
        icons_enabled = true,
        theme = lualine_theme,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { { "filename", newfile_status = true, symbols = { readonly = "🔒", modified = "✎ ", newfile = "✚ " } } },
        lualine_c = { "branch", "diff", "diagnostics" },
        lualine_x = { "filetype" },
        lualine_y = {
          function()
            local size = vim.fn.getfsize(vim.fn.expand("%"))
            if size < 0 then return "" end
            local suffixes = { "B", "KB", "MB", "GB" }
            local i = 1
            local fsize = size
            while fsize >= 1024 and i < #suffixes do
              fsize = fsize / 1024
              i = i + 1
            end
            if i == 1 then return string.format("%d %s", fsize, suffixes[i]) end
            return string.format("%.1f %s", fsize, suffixes[i])
          end,
        },
        lualine_z = {
          function()
            local line = vim.fn.line(".")
            local col = vim.fn.virtcol(".")
            local total = vim.fn.line("$")
            return string.format("%d:%d/%d", col, line, total)
          end,
        },
      },
    })
  end,
}
