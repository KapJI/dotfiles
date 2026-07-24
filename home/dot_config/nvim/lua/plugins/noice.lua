-- noice.nvim — vendored from our fork (KapJI/noice.nvim, branch
-- `patches`) so we ship cumulative fixes for nvim 0.12+ kinds
-- (bufwrite/shell_out/search_cmd), confirm-dialog rendering, State.skip
-- toast-fade dedup, merged-toast level preservation, classic-cmdline
-- popupmenu anchoring, search_count pattern strip, plus backports of
-- PRs #1041 / #1064 / #1066 / #1098 / #1120 / #1175.
return {
  "KapJI/noice.nvim",
  branch = "patches",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  -- <C-f>/<C-b> scroll the noice hover popup (LSP `K`) without focusing
  -- it. If no popup is visible, noice.lsp.scroll() returns false and the
  -- mapping falls through to the original buffer page-forward/back.
  keys = {
    {
      "<C-f>",
      function()
        if not require("noice.lsp").scroll(4) then
          return "<C-f>"
        end
      end,
      mode = { "n", "i", "s" },
      expr = true,
      silent = true,
      desc = "Scroll forward (noice hover or buffer)",
    },
    {
      "<C-b>",
      function()
        if not require("noice.lsp").scroll(-4) then
          return "<C-b>"
        end
      end,
      mode = { "n", "i", "s" },
      expr = true,
      silent = true,
      desc = "Scroll back (noice hover or buffer)",
    },
  },
  opts = {
    cmdline = {
      enabled = true,
      view = "cmdline", -- classic bottom row, syntax-highlighted by noice
      format = {
        -- Override the `input` format from "cmdline_input" (popup with
        -- prompt as title) to the bottom-row "cmdline" view. Otherwise
        -- vim's residual "Press ENTER" prompts and similar render as
        -- floating popups in the centre of the screen, with the prompt
        -- text as the popup title — visually noisy and inconsistent.
        input = { view = "cmdline", icon = "󰥻 " },
      },
    },
    messages = { enabled = true }, -- :echo / :echom / E-errors → nvim-notify toasts
    popupmenu = { enabled = true }, -- styled wildmenu for `:edit <Tab>`
    notify = { enabled = true, view = "notify" }, -- vim.notify → nvim-notify
    lsp = {
      progress = { enabled = true }, -- LSP indexing/loading toasts (lua_ls workspace, rust-analyzer, etc.); pyright filtered out below — its progress events have no message/percentage
      hover = { enabled = true }, -- routed through noice view; <C-f>/<C-b> scroll without focus
      signature = { enabled = true }, -- auto-popup as you type inside ( )
      -- NOTE: lsp.override (markdown utils + cmp) intentionally NOT
      -- enabled. render-markdown.nvim already handles styling in the
      -- hover popup buffers (filetype=markdown), so flipping the
      -- overrides on produces zero visible difference — only silences
      -- a :checkhealth noice warning. Not worth the config bloat.
    },
    presets = {
      lsp_doc_border = true, -- rounded border + offset for the hover popup
      long_message_to_split = true, -- multi-line output (E-stacks, :messages dump) → split, not toast
    },
    -- Override the `:Noice` / NoiceFzf history filter to exclude
    -- operator line-count reports (`5 lines >ed 1 time`, `3 lines
    -- yanked`, etc.). They still surface as a merged toast via the
    -- Messages route below; we just don't want them cluttering the
    -- recall list. Filter mirrors upstream defaults (config/init.lua)
    -- with a `cond` added to the kind="" branch.
    commands = {
      history = {
        filter = {
          any = {
            { event = "notify" },
            { error = true },
            { warning = true },
            {
              event = "msg_show",
              kind = { "", "echo", "echomsg", "lua_print", "list_cmd", "bufwrite", "shell_out" },
              cond = function(msg)
                local text = msg.content and msg:content() or ""
                return not (
                  text:match("^%d+ lines? [<>]ed")
                  or text:match("^%d+ lines? yanked")
                  or text:match("^%d+ %a+ lines?$")
                )
              end,
            },
            { event = "lsp", kind = "message" },
          },
        },
      },
    },
    routes = {
      -- Skip pyright's LSP progress events. Pyright emits sparse
      -- $/progress notifications with no message and no percentage,
      -- producing near-empty toasts that just clutter the corner.
      -- Other servers (lua_ls workspace scan, rust-analyzer indexing)
      -- are useful and stay enabled.
      {
        filter = {
          event = "lsp",
          kind = "progress",
          cond = function(msg)
            return msg.opts.progress and msg.opts.progress.client == "pyright"
          end,
        },
        opts = { skip = true },
      },

      -- Override the default Messages route to add `max_height = 19`,
      -- which lets messages ≥20 lines fall through to the
      -- `long_message_to_split` preset's route (`min_height = 20`,
      -- view = cmdline_output) instead of rendering as a giant toast
      -- (e.g. `:reg`, `:set all`). The preset route is appended after
      -- user routes, so without this max_height our override would
      -- catch long messages first. Kind list mirrors the fork's
      -- upstream-replacement default (bufwrite/shell_out are bundled
      -- there); shell_err/shell_ret/search_cmd are not listed since
      -- they're either short by nature or already handled upstream.
      {
        view = "notify",
        filter = {
          event = "msg_show",
          kind = { "", "echo", "echomsg", "lua_print", "list_cmd", "bufwrite", "shell_out" },
          max_height = 19,
        },
        opts = { replace = true, merge = true, title = "Messages" },
      },

      -- Merge consecutive errors into a refreshing toast rather than
      -- stacking — upstream's default Error route doesn't merge. This
      -- is a personal preference; pair it with the State.skip dedup
      -- removal in the fork (otherwise consecutive identical errors
      -- would be silently dropped at ingress). The fork also preserves
      -- the per-message level when merging, so we no longer need a
      -- `level = "error"` opt to keep nvim-notify rendering the toast
      -- with the red border.
      {
        view = "notify",
        filter = { error = true, max_height = 19 },
        opts = {
          replace = true,
          merge = true,
          title = "Error",
        },
      },
    },
  },
}
