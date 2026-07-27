-- Pure predicates for sensitive-file handling, extracted so they can be
-- unit-tested without booting the config. Consumed by config.autocmds.
local M = {}

-- True when a persistent undo file for `path` would leak secrets. Denylist of
-- known-sensitive locations:
--   - SSH files (~/.ssh/*)
--   - chezmoi's decrypted-edit temp dirs (…/chezmoi-encrypted<rand>/…)
--   - AWS creds/config (~/.aws/*)
--   - netrc (~/.netrc, and Windows's _netrc)
--   - dotenv files (.env, .env.<anything>) — but NOT .envrc, which direnv
--     commits to repos and is not a secret store.
-- Backslashes are normalized to forward slashes first so Windows paths
-- (C:\Users\…\.ssh\) match too. Returns an explicit boolean so callers and
-- tests get true/false, never a match string or nil.
function M.is_sensitive_undo_path(path)
  path = path:gsub("\\", "/")
  return path:match("/%.ssh/") ~= nil
    or path:match("chezmoi%-encrypted") ~= nil
    or path:match("/%.aws/") ~= nil
    or path:match("/%.netrc$") ~= nil
    or path:match("/_netrc$") ~= nil
    or path:match("/%.env$") ~= nil
    or path:match("/%.env%.[^/]*$") ~= nil
end

return M
