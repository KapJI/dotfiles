-- luacheck config for this dotfiles repo. Lives at the repo root (not
-- under home/, so chezmoi doesn't manage it and it keeps its literal
-- name) where luacheck's upward config search finds it from both the
-- pre-commit hook and an editor session editing the source tree.
--
-- std = luajit: Neovim (and wezterm) embed LuaJIT, so goto/labels and
-- \u{} escapes are valid — the stock lua5.1/5.3 stds reject them.
std = "luajit"

-- Globals injected by the host runtimes. `vim` is writable because
-- configs legitimately assign vim.g/o/bo/opt.* fields; the others we
-- only read. Deep member checking is the language server's job.
globals = { "vim" }
read_globals = {
  "Snacks",  -- snacks.nvim
  "wezterm", -- wezterm config
}

-- stylua owns formatting/line width; let luacheck focus on correctness
-- (unused vars, undefined globals, shadowing, redefinition) without
-- double-reporting on long comment/string lines stylua won't wrap.
max_line_length = false

-- chezmoi symlink sources contain a target path, not Lua.
exclude_files = { "**/symlink_*.lua" }
