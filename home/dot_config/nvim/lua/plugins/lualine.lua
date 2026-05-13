-- Statusline
return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim" },
  event = "VeryLazy",
  config = function()
    local inactive_lualine_bg = "#1e1e31"
    local lualine_theme = require("lualine.themes.catppuccin-mocha")
    lualine_theme.inactive.c.bg = inactive_lualine_bg

    -- Shortened path relative to cwd: `first/…/last/two` when >3 segments.
    -- Mirrors LazyVim's pretty_path (lua/lazyvim/util/lualine.lua) but
    -- without their util dependencies — uses plain cwd, not detected
    -- project root. Modified/readonly indicators are inlined since
    -- lualine's `symbols` option only applies to the built-in
    -- `filename` component.
    --
    -- Filename (last segment) renders bold via `Bold` (or `MatchParen`
    -- when modified, for a color shift in addition to bold); directory
    -- borrows just the fg color from `Comment` (a muted gray in
    -- catppuccin) — `fg_only=true` strips Comment's italic, which we
    -- don't want here. Lualine passes the component (self) as the
    -- first arg for function components, giving us access to its
    -- `create_hl` / `format_hl` / `get_default_hl` API.
    local lualine_utils = require("lualine.utils.utils")
    local function format(self, text, hl_group, opts)
      if not hl_group or hl_group == "" then return text end
      opts = opts or {}
      local cache_key = "_pp_" .. hl_group .. (opts.fg_only and "_fg" or "")
      self.hl_cache = self.hl_cache or {}
      if not self.hl_cache[cache_key] then
        local gui
        if not opts.fg_only then
          local parts = {}
          if lualine_utils.extract_highlight_colors(hl_group, "bold")   then parts[#parts + 1] = "bold"   end
          if lualine_utils.extract_highlight_colors(hl_group, "italic") then parts[#parts + 1] = "italic" end
          if #parts > 0 then gui = table.concat(parts, ",") end
        end
        self.hl_cache[cache_key] = self:create_hl({
          fg  = lualine_utils.extract_highlight_colors(hl_group, "fg"),
          gui = gui,
        }, cache_key)
      end
      return self:format_hl(self.hl_cache[cache_key]) .. text .. self:get_default_hl()
    end

    local function pretty_path(self)
      local abs = vim.fn.expand("%:p")
      if abs == "" then return "[No Name]" end
      local display = abs
      local cwd = vim.fn.getcwd()
      if abs:sub(1, #cwd + 1) == cwd .. "/" then display = abs:sub(#cwd + 2) end
      local parts = vim.split(display, "/")
      if #parts > 3 then
        parts = { parts[1], "…", unpack(parts, #parts - 1, #parts) }
      end

      local filename = parts[#parts]
      if vim.bo.modified then filename = filename .. " ✎" end
      -- "New file" — buffer has a name but the underlying file doesn't
      -- exist on disk yet (e.g. `:e new.txt` before first :w). Skip for
      -- non-file buftypes (terminal, nofile, help, etc).
      if vim.bo.buftype == "" and vim.fn.filereadable(abs) == 0 then
        filename = filename .. " ✚"
      end
      filename = format(self, filename, vim.bo.modified and "MatchParen" or "Bold")

      local dir = ""
      if #parts > 1 then
        dir = table.concat({ unpack(parts, 1, #parts - 1) }, "/") .. "/"
        dir = format(self, dir, "Comment", { fg_only = true })
      end

      local out = dir .. filename
      if vim.bo.readonly then out = "🔒 " .. out end
      return out
    end

    require("lualine").setup({
      options = {
        icons_enabled = true,
        theme = lualine_theme,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch" },
        lualine_c = { pretty_path, "diff" },
        lualine_x = { "diagnostics", "filetype" },
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
