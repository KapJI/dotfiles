-- Curated nvim tips, drawn from the laminated cheatsheet at
-- ~/Documents/nvim-cheatsheet.html. Three picks per launch, shuffled.
-- Keep in sync with the cheatsheet when it grows.

local M = {}

local tips = {
  { "ciw",       "change inner word"                          },
  { "da{",       "delete braces with their content"           },
  { "yi\"",      "yank everything inside quotes"              },
  { "=ip",       "auto-indent / reformat paragraph"           },
  { "ysiw)",     "wrap word in ( ) — nvim-surround"           },
  { "ds\"",      "delete the surrounding \" — nvim-surround"  },
  { "cs\"'",     "change \" → ' around — nvim-surround"       },
  { ".",         "repeat last change — cornerstone"           },
  { "*cgn .",    "change first match · then . repeats"        },
  { "gn / gN",   "visual-select next/prev search match"       },
  { "qa … q",    "record macro into register a"               },
  { "@a / @@",   "play macro / replay last"                   },
  { ":%s//x/g",  "substitute, reusing last search pattern"    },
  { ":cdo …",    "run a command on every quickfix entry"      },
  { "ma  'a",    "set buffer-mark a · jump back to it"        },
  { "''",        "jump to position before the last jump"      },
  { "'.",        "jump to last edit"                          },
  { "\"0p",      "paste last yank (survives d/c)"             },
  { "\"+y",      "yank to system clipboard"                   },
  { "<C-r>=",    "expression register: live math in insert"   },
  { "[x",        "jump up one treesitter scope (this config)" },
  { "<leader>j", "toggle split/join — treesj"                 },
  { "<C-a>",     "increment number / bool / date / semver"    },
}

-- Pick `n` random tips and return them as a list of strings ready
-- for snacks.dashboard's `text` section.
function M.pick(n)
  math.randomseed(os.time())
  local copy = {}
  for i, t in ipairs(tips) do copy[i] = t end
  -- Fisher-Yates partial shuffle
  for i = #copy, #copy - n + 1, -1 do
    local j = math.random(i)
    copy[i], copy[j] = copy[j], copy[i]
  end

  -- snacks treats a list of Text items as multiple runs on ONE line.
  -- For multiple lines, embed \n in a single Text item — block() splits on \n.
  -- Section-level title/icon (in snacks.lua) provides the heading.
  -- Pad by display width, not byte count — Unicode like `…` (U+2026)
  -- is 3 bytes but only 1 display column, which throws off `%-14s`.
  local KEYMAP_WIDTH = 14
  local parts = {}
  for i = #copy, #copy - n + 1, -1 do
    local t = copy[i]
    local pad = string.rep(" ", math.max(0, KEYMAP_WIDTH - vim.fn.strdisplaywidth(t[1])))
    -- 2-space prefix matches the indent of named-section children
    -- (Recent Files / Projects). The title (in snacks.lua) sits at col 0.
    table.insert(parts, "  " .. t[1] .. pad .. "  " .. t[2])
  end
  return { { table.concat(parts, "\n"), hl = "Comment" } }
end

return M
