-- Pure predicates for sensitive-file handling, extracted so they can be
-- unit-tested without booting the config. Consumed by config.autocmds.
local M = {}

-- True when a persistent undo file for `path` would leak secrets: SSH files
-- (~/.ssh/*) and chezmoi's decrypted-edit temp dirs
-- (…/chezmoi-encrypted<rand>/…). Backslashes are normalized to forward
-- slashes first so Windows paths (C:\Users\…\.ssh\) match too. Returns an
-- explicit boolean so callers and tests get true/false, never a match
-- string or nil.
function M.is_sensitive_undo_path(path)
  path = path:gsub("\\", "/")
  return path:match("/%.ssh/") ~= nil or path:match("chezmoi%-encrypted") ~= nil
end

return M
