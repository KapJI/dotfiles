-- vim.opt.* settings (no plugins required)

vim.opt.mouse = "a"
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.updatetime = 300            -- faster CursorHold events (default 4000ms)
vim.opt.signcolumn = "yes"          -- always show sign column to avoid text shifting
vim.opt.number = true
vim.opt.relativenumber = true       -- show relative line numbers for easy jump counts
vim.opt.cursorline = true
vim.opt.showmode = false            -- mode is shown in lualine instead
vim.opt.scrolloff = 1               -- keep 1 line visible above/below cursor
vim.opt.sidescrolloff = 1           -- keep 1 column visible left/right of cursor
vim.opt.ignorecase = true           -- case-insensitive search...
vim.opt.smartcase = true            -- ...unless query contains uppercase
vim.opt.splitright = true           -- vertical splits open to the right
vim.opt.splitbelow = true           -- horizontal splits open below
vim.opt.inccommand = "split"        -- live preview of :s substitutions

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true             -- persistent undo across sessions

vim.opt.termguicolors = true        -- 24-bit color support

vim.opt.list = true
vim.opt.listchars = { extends = ">", precedes = "<", tab = "  ", trail = "~" }

-- Treesitter-based folding. Start fully unfolded (foldlevel 99) so the
-- fold column shows markers only on lines that are currently folded.
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = ""                  -- inline text-only fold preview
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldcolumn = "auto:1"          -- show only when something foldable is in view
vim.opt.fillchars:append({ fold = " " })
