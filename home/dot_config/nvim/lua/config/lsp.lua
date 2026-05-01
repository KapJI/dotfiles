-- LSP server configurations and per-buffer keymaps.
-- Loaded after plugins so nvim-lspconfig defaults are available.

-- Diagnostics config
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { source = true },
})

-- LSP keymaps (set when a language server attaches to a buffer)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local keyset = vim.keymap.set
    local opts = function(desc) return { buffer = ev.buf, silent = true, desc = desc } end
    keyset("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
    keyset("n", "gy", vim.lsp.buf.type_definition, opts("Go to type definition"))
    keyset("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
    keyset("n", "gr", function() require("fzf-lua").lsp_references() end, opts("Go to references"))
    keyset("n", "K", vim.lsp.buf.hover, opts("Show documentation"))
    -- <leader>cr is bound globally by inc-rename.nvim (live-preview rename).
    -- Don't shadow it here with a buffer-local binding to vim.lsp.buf.rename.
    keyset({ "n", "v" }, "<leader>ca", function() require("fzf-lua").lsp_code_actions() end, opts("Code action"))
    -- <leader>cf is bound globally by conform.nvim (with lsp_fallback for filetypes
    -- without a CLI formatter). Don't shadow it here with a buffer-local LSP-only
    -- binding.
  end,
})

local keyset = vim.keymap.set
keyset("n", "<leader>cd", function() require("fzf-lua").diagnostics_document() end, { desc = "Document diagnostics" })

-- LSP server configurations
vim.lsp.config("nil_ls", {})

vim.lsp.config("pyright", {
  settings = {
    pyright = { disableOrganizeImports = true },  -- let ruff handle imports
  },
})

vim.lsp.config("ruff", {})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file("", true),  -- nvim runtime + plugin sources
      },
      diagnostics = { globals = { "vim" } },
      telemetry = { enable = false },
    },
  },
})

-- Servers whose binaries come from outside mason (uv-tool / nix / system).
-- mason-installed servers auto-enable via mason-lspconfig's automatic_enable.
local function executable(name) return vim.fn.executable(name) == 1 end
local servers = {}
if executable("nil") then table.insert(servers, "nil_ls") end
if executable("pyright-langserver") or executable("pyright") then table.insert(servers, "pyright") end
if executable("ruff") then table.insert(servers, "ruff") end
if #servers > 0 then vim.lsp.enable(servers) end
