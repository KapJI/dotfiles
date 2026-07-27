-- Load the real autocmds under test (undo protection, whitespace strip,
-- title). plenary runs each spec file in its own nvim with minimal_init,
-- so this is a clean instance.
require("config.autocmds")

local uv = vim.uv or vim.loop
vim.o.undofile = true -- global ON; buffer-locals inherit unless protected

local function tmpdir()
  local d = vim.fn.tempname()
  vim.fn.mkdir(d, "p")
  return d
end

describe("undo secret-protection", function()
  it("disables undofile when reading a file under .ssh", function()
    local d = tmpdir()
    vim.fn.mkdir(d .. "/.ssh", "p")
    local f = d .. "/.ssh/config"
    vim.fn.writefile({ "secret" }, f)
    vim.cmd.edit({ args = { f } })
    assert.is_false(vim.bo.undofile)
    vim.cmd("bwipeout!")
  end)

  it("resolves a symlink pointing into .ssh", function()
    local d = tmpdir()
    vim.fn.mkdir(d .. "/.ssh", "p")
    vim.fn.writefile({ "secret" }, d .. "/.ssh/config")
    local link = d .. "/alias"
    uv.fs_symlink(d .. "/.ssh/config", link)
    vim.cmd.edit({ args = { link } })
    assert.is_false(vim.bo.undofile)
    vim.cmd("bwipeout!")
  end)

  it("disables undofile for a chezmoi decrypted temp", function()
    local d = tmpdir() .. "/chezmoi-encrypted123"
    vim.fn.mkdir(d, "p")
    local f = d .. "/plain"
    vim.fn.writefile({ "secret" }, f)
    vim.cmd.edit({ args = { f } })
    assert.is_false(vim.bo.undofile)
    vim.cmd("bwipeout!")
  end)

  it("protects a :saveas into .ssh and writes no undo file", function()
    local d = tmpdir()
    vim.fn.mkdir(d .. "/.ssh", "p")
    vim.cmd.edit({ args = { d .. "/plain.txt" } })
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "content" })
    vim.cmd("saveas! " .. vim.fn.fnameescape(d .. "/.ssh/config"))
    assert.is_false(vim.bo.undofile)
    vim.cmd("normal! ochange")
    vim.cmd("write")
    assert.equals(0, vim.fn.filereadable(vim.fn.undofile(d .. "/.ssh/config")))
    vim.cmd("bwipeout!")
  end)

  it("leaves undofile ON for a normal file (no over-fire)", function()
    local d = tmpdir()
    local f = d .. "/notes.md"
    vim.fn.writefile({ "hi" }, f)
    vim.cmd.edit({ args = { f } })
    assert.is_true(vim.bo.undofile)
    vim.cmd("bwipeout!")
  end)
end)

describe("whitespace strip on save", function()
  it("preserves trailing bytes in a binary buffer", function()
    local d = tmpdir()
    local f = d .. "/blob.bin"
    vim.cmd("enew")
    vim.bo.binary = true
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "payload   " })
    vim.cmd("write! " .. vim.fn.fnameescape(f))
    assert.equals("payload   ", vim.fn.readfile(f, "b")[1])
    vim.cmd("bwipeout!")
  end)

  it("strips trailing whitespace on a normal buffer by default", function()
    local d = tmpdir()
    local f = d .. "/plain.txt"
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "code   " })
    vim.cmd("write! " .. vim.fn.fnameescape(f))
    assert.equals("code", vim.fn.readfile(f)[1])
    vim.cmd("bwipeout!")
  end)

  it("honors the per-buffer disable_strip_whitespace escape hatch", function()
    local d = tmpdir()
    local f = d .. "/fixture.txt"
    vim.cmd("enew")
    vim.b.disable_strip_whitespace = true
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "semantic   " })
    vim.cmd("write! " .. vim.fn.fnameescape(f))
    assert.equals("semantic   ", vim.fn.readfile(f)[1])
    vim.cmd("bwipeout!")
  end)
end)

describe("terminal title", function()
  it("strips control chars from the filename before the title", function()
    vim.cmd("enew")
    vim.api.nvim_buf_set_name(0, "/tmp/ev\27il\7.txt") -- ESC + BEL
    vim.api.nvim_exec_autocmds("BufFilePost", { buffer = 0 })
    vim.wait(200, function()
      return false
    end) -- let the vim.schedule'd title update run
    assert.is_nil(vim.o.titlestring:find("[%c]"))
    vim.cmd("bwipeout!")
  end)
end)
