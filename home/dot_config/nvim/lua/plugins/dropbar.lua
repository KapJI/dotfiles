-- Bekaboo/dropbar.nvim — VSCode-style breadcrumb winbar.
-- Path > Module > Class > method, click any segment to navigate, or
-- <leader>; to open an interactive picker.
return {
  "Bekaboo/dropbar.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    {
      "<leader>;",
      function()
        require("dropbar.api").pick()
      end,
      desc = "Pick from breadcrumbs (dropbar)",
    },
  },
  opts = {
    icons = {
      ui = {
        bar = {
          -- Default is "<chevron><space>" — only a trailing space, which
          -- looks tight before each segment. Prepend one space so the
          -- chevron sits between two single spaces.
          separator = " \u{F460} ",
        },
      },
    },
    bar = {
      -- Skip UI / scratch / non-file buffers. The default `enable`
      -- already excludes most, but we add our project-specific
      -- filetypes (snacks panes, neominimap, etc.) so the
      -- breadcrumb only renders on real source buffers.
      enable = function(buf, win, _)
        local ft = vim.bo[buf].filetype
        if
          vim.tbl_contains({
            "snacks_terminal",
            "snacks_dashboard",
            "neominimap",
            "TelescopePrompt",
            "lazy",
            "mason",
            "trouble",
            "qf",
            "help",
            "Outline",
            "aerial",
          }, ft)
        then
          return false
        end
        return vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" and not vim.wo[win].diff
      end,
    },
  },
}
