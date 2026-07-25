local sensitive = require("config.sensitive")

describe("is_sensitive_undo_path", function()
  local positives = {
    "/Users/x/.ssh/config",
    "/home/x/.ssh/id_ed25519",
    [[C:\Users\x\.ssh\config]], -- Windows backslashes
    "/tmp/chezmoi-encrypted123/.ssh/config",
    "/tmp/chezmoi-encrypted999/foo", -- chezmoi temp without .ssh
  }
  local negatives = {
    "/Users/x/notes/ssh_notes.md", -- "ssh" but not "/.ssh/"
    "/Users/x/.sshfoo/config", -- ".ssh" not followed by "/"
    "/Users/x/docs/chezmoi-encryption.md", -- "encrypt" not "encrypted"
    "/Users/x/project/init.lua",
  }

  for _, p in ipairs(positives) do
    it("matches sensitive path: " .. p, function()
      assert.is_true(sensitive.is_sensitive_undo_path(p))
    end)
  end
  for _, p in ipairs(negatives) do
    it("ignores non-sensitive path: " .. p, function()
      assert.is_false(sensitive.is_sensitive_undo_path(p))
    end)
  end
end)
