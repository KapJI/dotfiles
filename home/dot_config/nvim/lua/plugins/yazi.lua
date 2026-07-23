-- File explorer — yazi (Miller-columns: parent | current | preview,
-- h/l to ascend/descend). Replaces oil.nvim. Embeds the actual yazi
-- binary.
--
-- Eager-loaded so `open_for_directories` can hijack `nvim <dir>` the
-- way oil's `default_file_explorer` did — the autocmd that intercepts
-- directory buffers must be registered before the first one opens.
return {
  "mikavilpas/yazi.nvim",
  lazy = false,
  keys = {
    { "-", "<Cmd>Yazi<CR>", desc = "Open yazi at the current file" },
  },
  init = function()
    -- Disable netrw. yazi.nvim's open_for_directories opens yazi as a
    -- float but, unlike oil's default_file_explorer, does not disable
    -- netrw — so netrw's own explorer buffer ends up stacked under the
    -- float. lazy.nvim runs init() during startup before runtime
    -- plugins load, so setting these globals here suppresses netrw.
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
  opts = {
    open_for_directories = true, -- open yazi on `nvim <dir>`
    -- Disable yazi's copy-relative-path action (<c-y>). On macOS it
    -- shells out to `grealpath` (GNU coreutils, g-prefixed), which isn't
    -- installed — so :checkhealth yazi warns. The action is niche; turn
    -- it off rather than pull coreutils-prefixed into the whole fleet
    -- for a macOS-only, one-keymap benefit (Linux has realpath natively).
    -- Deep-merged, so the rest of yazi's default keymaps are untouched.
    keymaps = { copy_relative_path_to_selected_files = false },
    -- Point the embedded yazi at a dedicated config dir
    -- (~/.config/yazi-nvim) where image preview is disabled. nvim's
    -- :terminal can't render terminal graphics protocols, so yazi's
    -- image escapes corrupt the pane — tracked upstream in
    -- neovim/neovim#32189 (PR #39496). The dir symlinks theme.toml +
    -- init.lua back to ~/.config/yazi so the catppuccin theme is
    -- shared; only yazi.toml differs (noop previewer for image/*).
    -- Standalone `yz` keeps ~/.config/yazi with real image preview.
    -- Revisit once #39496 ships graphics support to :terminal.
    config_home = vim.fn.expand("~/.config/yazi-nvim"),
  },
}
