local sensitive = require("config.sensitive")

describe("is_sensitive_path", function()
  local positives = {
    "/Users/x/.ssh/config",
    "/home/x/.ssh/id_ed25519",
    [[C:\Users\x\.ssh\config]], -- Windows backslashes
    "/tmp/chezmoi-encrypted123/.ssh/config",
    "/tmp/chezmoi-encrypted999/foo", -- chezmoi temp without .ssh
    "/Users/x/.aws/credentials", -- AWS creds
    "/home/x/.aws/config", -- AWS config (may hold sso/session data)
    "/Users/x/.netrc", -- netrc
    [[C:\Users\x\_netrc]], -- Windows netrc variant
    "/Users/x/project/.env", -- dotenv
    "/Users/x/project/.env.local", -- dotenv variant
    "/srv/app/.env.production", -- dotenv variant, absolute
  }
  local negatives = {
    "/Users/x/notes/ssh_notes.md", -- "ssh" but not "/.ssh/"
    "/Users/x/.sshfoo/config", -- ".ssh" not followed by "/"
    "/Users/x/docs/chezmoi-encryption.md", -- "encrypt" not "encrypted"
    "/Users/x/project/init.lua",
    "/Users/x/project/.envrc", -- direnv, committed, not a secret store
    "/Users/x/.awsome/config", -- ".aws" not followed by "/"
    "/Users/x/notes/environment.md", -- "env" but not a dotenv file
    "/Users/x/_netrcfoo", -- "_netrc" not at end of segment
  }

  for _, p in ipairs(positives) do
    it("matches sensitive path: " .. p, function()
      assert.is_true(sensitive.is_sensitive_path(p))
    end)
  end
  for _, p in ipairs(negatives) do
    it("ignores non-sensitive path: " .. p, function()
      assert.is_false(sensitive.is_sensitive_path(p))
    end)
  end
end)
