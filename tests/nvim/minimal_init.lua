-- Headless bootstrap for the config test suite. Puts the SOURCE config and
-- plenary on the runtimepath, registers plenary's busted command, and
-- isolates all writable state to a temp dir so tests never touch real undo
-- history / shada.
local this = debug.getinfo(1, "S").source:sub(2)
local tests_nvim = vim.fn.fnamemodify(this, ":p:h") -- .../tests/nvim
local repo_root = vim.fn.fnamemodify(tests_nvim, ":h:h") -- repo root
local config_dir = repo_root .. "/home/dot_config/nvim"

-- Isolate writable state: a per-process temp dir for undo, no shada, and no
-- swap, so the tests can't write to — or fail (E303) on a read-only —
-- ~/.local/state/nvim. run.sh also relocates XDG_STATE_HOME to a temp dir.
local state = vim.fn.tempname()
vim.fn.mkdir(state .. "/undo", "p")
vim.o.undodir = state .. "/undo"
vim.o.undofile = true
vim.o.shadafile = "NONE"
vim.o.swapfile = false

-- runtimepath: source config (so require("config.*") resolves) + plenary.
vim.opt.runtimepath:append(config_dir)
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/plenary.nvim")

-- plenary is lazy-loaded in the real config, so source its plugin file to
-- register :PlenaryBustedDirectory.
vim.cmd("runtime plugin/plenary.vim")
