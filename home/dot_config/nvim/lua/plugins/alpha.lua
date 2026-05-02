-- alpha-nvim: dashboard shown when nvim is launched without args.
-- Buttons route to existing fzf-lua / mason / lazy actions.
return {
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local dashboard = require("alpha.themes.dashboard")

      -- Compact 5-line header. Replace with `:AsciiArtFile` art if you want
      -- a flashier banner; this stays restrained so the buttons + recents
      -- get more attention.
      dashboard.section.header.val = {
        "                                                ",
        "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
        "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
        "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
        "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
        "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
        "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
        "                                                ",
      }

      -- Quick actions — wired to the same commands your <leader> keys use,
      -- so muscle memory transfers from the dashboard to in-buffer.
      -- Icons are Material Design Icons (MDI) codepoints in the U+F0000+
      -- range, rendered by Symbols Nerd Font Mono — same range as the
      -- working Lazy moon glyph.
      dashboard.section.buttons.val = {
        dashboard.button("f", "󰈞  Find file",     "<cmd>FzfLua files<cr>"),
        dashboard.button("r", "󰋚  Recent files",  "<cmd>FzfLua oldfiles<cr>"),
        dashboard.button("g", "󰍉  Live grep",     "<cmd>FzfLua live_grep<cr>"),
        dashboard.button("e", "󰈙  New file",      "<cmd>enew<cr>"),
        dashboard.button(".", "󰉋  Browse cwd",    "<cmd>Oil<cr>"),
        dashboard.button("l", "󰒲  Lazy",          "<cmd>Lazy<cr>"),
        dashboard.button("m", "󰏖  Mason",         "<cmd>Mason<cr>"),
        dashboard.button("q", "󰗼  Quit",          "<cmd>qa<cr>"),
      }

      -- Curated vim/nvim tips, drawn from the same teaching content as the
      -- printed cheatsheet (~/Documents/nvim-cheatsheet.html). Three picks
      -- shuffled each launch so the dashboard quietly teaches over time.
      local tips = {
        { "ciw",      "change inner word"                         },
        { "da{",      "delete braces with their content"          },
        { "yi\"",     "yank everything inside quotes"             },
        { "=ip",      "auto-indent / reformat paragraph"          },
        { "ysiw)",    "wrap word in ( ) — nvim-surround"          },
        { "ds\"",     "delete the surrounding \" — nvim-surround" },
        { "cs\"'",    "change \" → ' around — nvim-surround"      },
        { ".",        "repeat last change — cornerstone"          },
        { "*cgn .",   "change first match · then . repeats"       },
        { "gn / gN",  "visual-select next/prev search match"      },
        { "qa … q",   "record macro into register a"              },
        { "@a / @@",  "play macro / replay last"                  },
        { ":%s//x/g", "substitute, reusing last search pattern"   },
        { ":cdo …",   "run a command on every quickfix entry"     },
        { "ma  'a",   "set buffer-mark a · jump back to it"       },
        { "''",       "jump to position before the last jump"     },
        { "'.",       "jump to last edit"                         },
        { "\"0p",     "paste last yank (survives d/c)"            },
        { "\"+y",     "yank to system clipboard"                  },
        { "<C-r>=",   "expression register: live math in insert"  },
        { "[x",       "jump up one treesitter scope (this config)"},
        { "<leader>j","toggle split/join — treesj"                },
        { "<C-a>",    "increment number / bool / date / semver"   },
      }

      local function pick_tips(n)
        local copy = {}
        for i, t in ipairs(tips) do copy[i] = t end
        -- Fisher-Yates partial shuffle
        for i = #copy, #copy - n + 1, -1 do
          local j = math.random(i)
          copy[i], copy[j] = copy[j], copy[i]
        end
        local picked = {}
        for i = #copy, #copy - n + 1, -1 do table.insert(picked, copy[i]) end
        return picked
      end

      math.randomseed(os.time())
      local picked = pick_tips(3)
      local tip_lines = { "─── Tips of the day ───", "" }
      for _, t in ipairs(picked) do
        -- right-pad the keystroke column to 14 chars so descriptions align
        table.insert(tip_lines, string.format("  %-14s  %s", t[1], t[2]))
      end

      -- Width of the widest tip line — used to pad the footer so its centered
      -- block has the same left edge as the tips' centered block.
      local tips_width = 0
      for _, line in ipairs(tip_lines) do
        local w = vim.fn.strdisplaywidth(line)
        if w > tips_width then tips_width = w end
      end

      dashboard.section.tips = {
        type = "text",
        val = tip_lines,
        opts = { hl = "Comment", position = "center" },
      }

      -- Footer: filled in once Lazy reports its stats so we don't show "?" briefly.
      dashboard.section.footer.val = ""
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimStarted",
        callback = function()
          local stats = require("lazy").stats()
          local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
          local text = "  " .. stats.loaded .. "/" .. stats.count .. " plugins · " .. ms .. " ms"
          -- Trailing whitespace to match the tips block's width — when alpha
          -- centers this padded line, its visible content sits at the same
          -- x as the tips' left edge.
          local pad = tips_width - vim.fn.strdisplaywidth(text)
          if pad > 0 then text = text .. string.rep(" ", pad) end
          dashboard.section.footer.val = text
          pcall(vim.cmd.AlphaRedraw)
        end,
      })

      -- Catppuccin-friendly highlight groups
      dashboard.section.header.opts.hl  = "Type"      -- mauve-ish on Mocha
      dashboard.section.buttons.opts.hl = "Function"  -- blue-ish
      dashboard.section.footer.opts.hl  = "Comment"   -- subdued

      -- Insert the tips section between buttons and footer.
      dashboard.config.layout = {
        { type = "padding", val = 2 },
        dashboard.section.header,
        { type = "padding", val = 2 },
        dashboard.section.buttons,
        { type = "padding", val = 1 },
        dashboard.section.tips,
        { type = "padding", val = 1 },
        dashboard.section.footer,
      }

      dashboard.config.opts.noautocmd = true
      require("alpha").setup(dashboard.config)
    end,
  },
}
