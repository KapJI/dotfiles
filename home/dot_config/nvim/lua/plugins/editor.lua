-- Trivial editor plugins (each is a tiny default setup, no point splitting).
return {
  -- Surround: ys{motion}{char}, ds{char}, cs{old}{new}, S{char} in visual
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function() require("nvim-surround").setup() end,
  },

  -- Auto-close brackets and quotes
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function() require("nvim-autopairs").setup() end,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "VeryLazy",
    config = function() require("ibl").setup() end,
  },

  -- Auto-detect indentation style from file content
  {
    "NMAC427/guess-indent.nvim",
    event = "BufReadPost",
    config = function() require("guess-indent").setup() end,
  },

  -- Visual marks in sign column
  {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    config = function() require("marks").setup() end,
  },

  -- Multiple cursors
  {
    "mg979/vim-visual-multi",
    event = "VeryLazy",
  },
}
