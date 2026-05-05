-- noice.nvim — drives cmdline syntax highlighting (rendered classically
-- in the bottom row), the styled wildmenu, vim.notify routing through
-- nvim-notify, message routing (:echo / :echom / E-errors → toasts),
-- a recoverable history (<leader>Nh), and styled LSP hover/signature.
--
-- The `config` callback applies several upstream monkey-patches:
--   * PR #1120 popupmenu scrollbar (so the thumb tracks selection)
--   * Custom popupmenu position above the cmdline cursor
--   * Bypass noice.ui.state's silent dedup of consecutive identical
--     msg_show events (otherwise repeated `:badcmd` is invisible).
return {
  "folke/noice.nvim",
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
      function() if not require("noice.lsp").scroll(4)  then return "<C-f>" end end,
      mode = { "n", "i", "s" }, expr = true, silent = true,
      desc = "Scroll forward (noice hover or buffer)",
    },
    {
      "<C-b>",
      function() if not require("noice.lsp").scroll(-4) then return "<C-b>" end end,
      mode = { "n", "i", "s" }, expr = true, silent = true,
      desc = "Scroll back (noice hover or buffer)",
    },
  },
  opts = {
    cmdline = {
      enabled = true,
      view    = "cmdline", -- classic bottom row, syntax-highlighted by noice
      format  = {
        -- Override the `input` format from "cmdline_input" (popup with
        -- prompt as title) to the bottom-row "cmdline" view. Otherwise
        -- vim's residual "Press ENTER" prompts and similar render as
        -- floating popups in the centre of the screen, with the prompt
        -- text as the popup title — visually noisy and inconsistent.
        input = { view = "cmdline", icon = "󰥻 " },
      },
    },
    messages   = { enabled = true },                  -- :echo / :echom / E-errors → nvim-notify toasts
    popupmenu  = { enabled = true },                  -- styled wildmenu for `:edit <Tab>`
    notify     = { enabled = true, view = "notify" }, -- vim.notify → nvim-notify
    lsp = {
      progress  = { enabled = true },  -- LSP indexing/loading toasts (lua_ls workspace, rust-analyzer, etc.); pyright filtered out below — its progress events have no message/percentage
      hover     = { enabled = true },  -- routed through noice view; <C-f>/<C-b> scroll without focus
      signature = { enabled = true },  -- auto-popup as you type inside ( )
      -- NOTE: lsp.override (markdown utils + cmp) intentionally NOT
      -- enabled. render-markdown.nvim already handles styling in the
      -- hover popup buffers (filetype=markdown), so flipping the
      -- overrides on produces zero visible difference — only silences
      -- a :checkhealth noice warning. Not worth the config bloat.
    },
    presets = {
      lsp_doc_border        = true, -- rounded border + offset for the hover popup
      long_message_to_split = true, -- multi-line output (E-stacks, :messages dump) → split, not toast
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
          kind  = "progress",
          cond  = function(msg)
            return msg.opts.progress and msg.opts.progress.client == "pyright"
          end,
        },
        opts = { skip = true },
      },

      -- Override noice's built-in `Messages` route (config/routes.lua:79).
      -- Upstream forces opts={ replace=true, merge=true } for plain
      -- msg_show kinds, so a second `:set scrolloff?` while the first
      -- toast is still visible silently replaces it instead of stacking.
      -- Drop replace/merge so each invocation gets its own toast — same
      -- behavior errors get from the error route (line 87) by default.
      {
        view = "notify",
        filter = {
          event = "msg_show",
          kind  = { "", "echo", "echomsg", "lua_print", "list_cmd" },
        },
        opts = { title = "Messages" },
      },
    },
  },
  config = function(_, opts)
    require("noice").setup(opts)

    -- Workaround for noice PR #1120 (mergeable but unmerged since
    -- 2025-07-05): the cmdline popupmenu scrollbar's autocmd is bound
    -- to the menu's winid, but on_select fires WinScrolled without that
    -- pattern, so the thumb mounts at line 1 and never moves. Patch
    -- both functions in-place after setup. Drop this when upstream
    -- merges the PR.
    local pm   = require("noice.ui.popupmenu.nui")
    local Util = require("noice.util")

    -- Force the popupmenu to anchor 1 row above the cmdline, aligned to
    -- the cmdline cursor column (so the popup's bottom-left corner is
    -- at the cursor and the popup extends UP and to the RIGHT). Upstream's
    -- auto-anchoring in M.opts() conditions on `pos.screenpos.row ==
    -- vim.go.lines`, which doesn't fire reliably for the classic "cmdline"
    -- view's popup window. Wrap M.opts to set position/anchor explicitly.
    local Api = require("noice.api")
    local original_pm_opts = pm.opts
    pm.opts = function(state)
      local o, padding = original_pm_opts(state)
      if state.grid == -1 then -- is_cmdline
        local pos = Api.get_cmdline_position()
        local col = 0
        if pos then
          col = pos.screenpos.col + state.col - padding.left
          if col < 0 then col = 0 end
        end
        o.position = {
          -- noice's classic "cmdline" view renders its popup at row
          -- vim.o.lines - cmdheight (overlapping lualine), not at vim's
          -- own cmdline row. Subtract one more so our popupmenu sits
          -- one row above noice's cmdline render.
          row = vim.o.lines - vim.o.cmdheight - 1,
          col = col,
        }
        o.anchor = "SW"
      end
      return o, padding
    end

    pm.on_select = function(state, redraw)
      if not pm.menu then return end
      if state.selected == -1 then
        vim.wo[pm.menu.winid].cursorline = false
      else
        vim.wo[pm.menu.winid].cursorline = true
        vim.api.nvim_win_set_cursor(pm.menu.winid, { state.selected + 1, 0 })
        vim.api.nvim_exec_autocmds("WinScrolled", {
          pattern  = tostring(pm.menu.winid),
          modeline = false,
        })
        if redraw ~= false and Util.is_blocking() then
          Util.redraw()
        end
      end
    end

    -- Scrollbar:update — verbatim copy of upstream view/scrollbar.lua
    -- with one line patched: `pct` now uses (topline - 1) / max_scroll
    -- and guards max_scroll == 0. Method is replaced wholesale because
    -- Lua doesn't allow per-line splicing.
    local Scrollbar = require("noice.view.scrollbar")
    function Scrollbar:update()
      if not vim.api.nvim_win_is_valid(self.winnr) then
        return self:hide()
      end

      local pos = vim.api.nvim_win_get_position(self.winnr)
      local dim = {
        row    = pos[1] - self.opts.padding.top,
        col    = pos[2] - self.opts.padding.left,
        width  = vim.api.nvim_win_get_width(self.winnr)  + self.opts.padding.left + self.opts.padding.right,
        height = vim.api.nvim_win_get_height(self.winnr) + self.opts.padding.top  + self.opts.padding.bottom,
      }
      local buf_height = Util.nui.win_buf_height(self.winnr)

      if self.opts.autohide and dim.height >= buf_height then
        self:hide()
        return
      elseif not self.visible then
        self:show()
      end

      if not (vim.api.nvim_win_is_valid(self.bar.winnr) and vim.api.nvim_win_is_valid(self.thumb.winnr)) then
        self:hide()
        self:show()
      end

      local zindex = vim.api.nvim_win_get_config(self.winnr).zindex or 50
      Util.win_apply_config(self.bar.winnr, {
        height = dim.height,
        width  = 1,
        col    = dim.col + dim.width - 1,
        row    = dim.row,
        zindex = zindex + 1,
      })

      local thumb_height = math.max(1, math.floor(dim.height * dim.height / buf_height + 0.5))
      local view = vim.api.nvim_win_call(self.winnr, vim.fn.winsaveview)
      local max_scroll = buf_height - dim.height
      local pct = max_scroll > 0 and math.min((view.topline - 1) / max_scroll, 1) or 0
      local thumb_offset = math.floor(pct * (dim.height - thumb_height) + 0.5)

      Util.win_apply_config(self.thumb.winnr, {
        width  = 1,
        height = thumb_height,
        row    = dim.row + thumb_offset,
        col    = dim.col + dim.width - 1,
        zindex = zindex + 2,
      })
    end

    -- Bypass noice.ui.state's dedup of consecutive identical msg_show
    -- events. State.skip (state.lua:20) is hard-coded with no config
    -- option and silently swallows the second `:badcmd`, the second
    -- save error, etc. Patch on_show to drop the State.skip check
    -- while leaving on_showmode and on_confirm untouched. Body is a
    -- verbatim copy of upstream noice/ui/msg.lua:85-122 with the
    -- State.skip line removed.
    local msg     = require("noice.ui.msg")
    local Cmdline = require("noice.ui.cmdline")
    local Manager = require("noice.message.manager")
    local Hacks   = require("noice.util.hacks")
    local Message = require("noice.message")

    msg.on_show = function(event, kind, content, replace_last)
      if kind == msg.kinds.return_prompt then
        return msg.on_return_prompt()
      elseif kind == msg.kinds.confirm
          or kind == msg.kinds.confirm_sub
          or kind == msg.kinds.number_prompt then
        return msg.on_confirm(event, kind, content)
      end

      -- Skipped intentionally: State.skip(event, kind, content, replace_last)

      if msg.last and replace_last then
        Manager.clear({ message = msg.last })
        msg.last = nil
      end

      local message
      if kind == msg.kinds.search_count then
        message = msg.get(event, kind)
        Hacks.fix_nohlsearch()
      else
        message = Message(event, kind)
        message.cmdline = Cmdline.active
      end

      message:set(content)
      message:trim_empty_lines()
      if msg.is_error(kind)   then message.level = "error" end
      if msg.is_warning(kind) then message.level = "warn"  end

      msg.last = message
      Manager.add(message)
    end

    -- Fix confirm dialog on nvim 0.12+:
    --
    -- (1) issue #1198 (miszo's workaround): the confirm message and
    --     the cmdline prompt arrive without a newline separator, so
    --     noice's {confirm} formatter merges the question text and
    --     the [Y]es/(N)o/(C)ancel buttons onto one line. Insert a
    --     newline before appending the prompt.
    --
    -- (2) duplicate cmdline rendering: vim emits a SECOND cmdline_show
    --     after the confirm popup is already up, which the original
    --     on_show would route through the cmdline view, producing a
    --     bottom-row dialog underneath the popup. Track an `in_confirm`
    --     flag set when we consume confirm_message and cleared on
    --     `_on_hide`; while it's true, drop further cmdline_show
    --     events. The popup already shows the prompt (combined with
    --     the question), so nothing is lost.
    -- Bypass noice.ui.state.skip for `msg_show kind="confirm"` events.
    -- State.skip dedupes consecutive identical msg_show events globally;
    -- for `:q` on a modified buffer it wrongly silences the SECOND
    -- invocation (same E37/confirm content as the first), so
    -- msg.on_confirm bails before setting Cmdline.confirm_message and
    -- the cmdline_show that follows falls through to the regular
    -- cmdline view as a bottom-row "[Y]es, (N)o, (C)ancel:" prompt
    -- without the question. Selectively pass-through for confirm
    -- events; leave skip behavior intact for everything else
    -- (showmode, etc.).
    local State            = require("noice.ui.state")
    local orig_state_skip  = State.skip
    State.skip = function(event, ...)
      local args = { ... }
      if event == "msg_show" and args[1] == "confirm" then
        return nil
      end
      return orig_state_skip(event, ...)
    end

    -- Confirm dialog patches for nvim 0.12+:
    --
    -- (a) issue #1198 (miszo's workaround): the confirm message and
    --     the cmdline prompt arrive without a newline separator, so
    --     noice's {confirm} formatter merges the question text and
    --     the [Y]es/(N)o/(C)ancel buttons onto one line. Insert a
    --     newline before appending the prompt.
    --
    -- (b) invalid-key retry: vim's confirm() re-emits cmdline_show
    --     with the same prompt on every invalid keypress, WITHOUT
    --     re-emitting msg_show kind=confirm. A naive "remove on
    --     _on_hide, fall through on the retry" approach destroys
    --     the popup and renders a bottom-row cmdline prompt. Instead
    --     defer Manager.remove via a generation counter — a retry
    --     bumps gen so the pending remove cancels itself and the
    --     popup stays visible across invalid keypresses.
    local Cmdline = require("noice.ui.cmdline")
    local Hacks   = require("noice.util.hacks")
    local active_message = nil
    local gen = 0

    local function arm_hide()
      Cmdline._on_hide = function()
        gen = gen + 1
        local my_gen = gen
        local m = active_message
        vim.schedule(function()
          if my_gen == gen then
            -- Real dismissal: remove popup AND restore the cursor that
            -- we hid while the confirm dialog was up.
            if m then Manager.remove(m) end
            active_message = nil
            Hacks.show_cursor()
          end
        end)
      end
    end

    local orig_on_show = Cmdline.on_show
    Cmdline.on_show = function(event, content, pos, firstc, prompt, indent, level)
      if Cmdline.confirm_message then
        local message = Cmdline.confirm_message
        message:newline()
        message:append(prompt)
        Cmdline.confirm_message = nil
        Manager.add(message)
        active_message = message
        -- Hide vim's cursor while confirm popup is up. Otherwise the
        -- noice cmdline closes (its row is reclaimed by lualine) and
        -- vim's cursor lands on the statusline, painting one cell with
        -- the cursor highlight.
        Hacks.hide_cursor()
        arm_hide()
        return
      end
      if active_message and prompt ~= "" then
        -- Retry from invalid keypress: bump gen to cancel the pending
        -- deferred remove, re-arm hide for the next round. Popup stays.
        gen = gen + 1
        arm_hide()
        return
      end
      active_message = nil
      return orig_on_show(event, content, pos, firstc, prompt, indent, level)
    end
  end,
}
