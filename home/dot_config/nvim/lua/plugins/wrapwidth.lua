-- wrapwidth: soft-wrap at a chosen column via inline virtual spaces; the
-- file is never modified. A negative width is a margin from the window's
-- right edge, so it follows window resizes on its own.
--
-- Soft wrap is on for markdown and toggled elsewhere with <leader>mw. Lines
-- wrap short of the neominimap float (it overlays the right edge, see
-- neominimap.lua) while a minimap is attached, and at the window edge
-- otherwise. `linebreak` makes either wrap on word boundaries.
local function minimap_width()
  local cfg = vim.g.neominimap or {}
  return (cfg.float or {}).minimap_width or 0
end

local function has_minimap(winid)
  local ok, window_map = pcall(require, "neominimap.window.float.window_map")
  if not ok then
    return false
  end
  local mwinid = window_map.get_minimap_winid(winid)
  return mwinid ~= nil and vim.api.nvim_win_is_valid(mwinid)
end

-- Re-run :Wrapwidth only when the target changes: it recomputes every line.
local function apply(winid)
  local buf = vim.api.nvim_win_get_buf(winid)
  if not vim.b[buf].user_softwrap then
    return
  end
  local n = has_minimap(winid) and -minimap_width() or 0
  if vim.b[buf].user_wrapwidth ~= n then
    vim.b[buf].user_wrapwidth = n
    vim.api.nvim_win_call(winid, function()
      vim.cmd("Wrapwidth " .. n)
    end)
  end
end

local function enable(winid)
  local buf = vim.api.nvim_win_get_buf(winid)
  vim.b[buf].user_softwrap = true
  vim.b[buf].user_wrapwidth = nil
  for _, opt in ipairs({ "wrap", "linebreak", "breakindent" }) do
    vim.wo[winid][0][opt] = true
  end
  apply(winid)
end

local function disable(winid)
  local buf = vim.api.nvim_win_get_buf(winid)
  vim.b[buf].user_softwrap = false
  vim.b[buf].user_wrapwidth = nil
  vim.api.nvim_win_call(winid, function()
    vim.cmd("Wrapwidth 0")
  end)
  vim.wo[winid][0].wrap = false
end

return {
  "rickhowe/wrapwidth",
  cmd = "Wrapwidth",
  init = function()
    local group = vim.api.nvim_create_augroup("user_wrapwidth", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "markdown",
      callback = function()
        enable(vim.api.nvim_get_current_win())
      end,
    })
    local function apply_all()
      for _, winid in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(winid) then
          apply(winid)
        end
      end
    end
    -- A minimap attaches after BufWinEnter (deferred past neominimap's own
    -- schedules, as in neominimap.lua); toggles announce UserMinimapChanged.
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = group,
      callback = function()
        vim.defer_fn(apply_all, 30)
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = "UserMinimapChanged",
      callback = apply_all,
    })
  end,
  keys = {
    {
      "<leader>mw",
      function()
        local winid = vim.api.nvim_get_current_win()
        if vim.b.user_softwrap then
          disable(winid)
        else
          enable(winid)
        end
      end,
      desc = "Toggle soft wrap",
    },
  },
}
