-- dial.nvim: smarter Ctrl-A / Ctrl-X. Beyond built-in number increment, also
-- toggles booleans (true↔false, yes↔no), increments dates, semver, hex/binary,
-- and cycles through registered word groups (and↔or, &&↔||).
return {
  {
    "monaqa/dial.nvim",
    keys = {
      { "<C-a>",  function() require("dial.map").manipulate("increment", "normal") end,  mode = "n", desc = "Increment (dial)" },
      { "<C-x>",  function() require("dial.map").manipulate("decrement", "normal") end,  mode = "n", desc = "Decrement (dial)" },
      { "<C-a>",  function() require("dial.map").manipulate("increment", "visual") end,  mode = "v", desc = "Increment (dial)" },
      { "<C-x>",  function() require("dial.map").manipulate("decrement", "visual") end,  mode = "v", desc = "Decrement (dial)" },
      { "g<C-a>", function() require("dial.map").manipulate("increment", "gvisual") end, mode = "v", desc = "Sequential increment" },
      { "g<C-x>", function() require("dial.map").manipulate("decrement", "gvisual") end, mode = "v", desc = "Sequential decrement" },
    },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.integer.alias.binary,
          augend.integer.alias.octal,
          augend.constant.alias.bool,                                                                   -- true ↔ false
          augend.constant.new({ elements = { "yes",   "no"    }, word = true,  cyclic = true }),
          augend.constant.new({ elements = { "True",  "False" }, word = true,  cyclic = true }),
          augend.constant.new({ elements = { "and",   "or"    }, word = true,  cyclic = true }),
          augend.constant.new({ elements = { "&&",    "||"    }, word = false, cyclic = true }),
          augend.date.alias["%Y-%m-%d"],
          augend.date.alias["%Y/%m/%d"],
          augend.date.alias["%H:%M"],
          augend.semver.alias.semver,                                                                   -- 1.2.3 → 1.2.4 / 1.3.0 / 2.0.0 (cursor decides scope)
        },
      })
    end,
  },
}
