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

-- LSP keymaps (set when a language server attaches to a buffer).
-- Named augroup (cleared on re-source) so re-running this file doesn't
-- register the LspAttach handler twice.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
  callback = function(ev)
    local keyset = vim.keymap.set
    local opts = function(desc)
      return { buffer = ev.buf, silent = true, desc = desc }
    end
    keyset("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
    keyset("n", "gy", vim.lsp.buf.type_definition, opts("Go to type definition"))
    keyset("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
    -- nowait: gr is a prefix of Neovim's default grr/gra/gri/grn LSP maps,
    -- so without it, pressing gr stalls for timeoutlen (~1s) to disambiguate.
    -- Fire immediately — those built-ins are redundant with this scheme
    -- (references=gr, code action=<leader>ca, implementation=gi, rename=<leader>cr).
    keyset("n", "gr", function()
      require("fzf-lua").lsp_references()
    end, vim.tbl_extend("force", opts("Go to references"), { nowait = true }))
    keyset("n", "K", vim.lsp.buf.hover, opts("Show documentation"))
    -- <leader>cr is bound globally by inc-rename.nvim (live-preview rename).
    -- Don't shadow it here with a buffer-local binding to vim.lsp.buf.rename.
    keyset({ "n", "v" }, "<leader>ca", function()
      require("fzf-lua").lsp_code_actions()
    end, opts("Code action"))
    -- <leader>cf is bound globally by conform.nvim (with LSP fallback for filetypes
    -- without a CLI formatter). Don't shadow it here with a buffer-local LSP-only
    -- binding.
  end,
})

local keyset = vim.keymap.set
keyset("n", "<leader>cd", function()
  require("fzf-lua").diagnostics_document()
end, { desc = "Document diagnostics" })

-- LSP server configurations
vim.lsp.config("nil_ls", {})

vim.lsp.config("pyright", {
  settings = {
    pyright = { disableOrganizeImports = true }, -- let ruff handle imports
  },
})

vim.lsp.config("ruff", {})

vim.lsp.config("rust_analyzer", {})

-- Workspace libraries (nvim runtime + require()d plugin modules) are
-- supplied on demand by lazydev.nvim (lua/plugins/lazydev.lua) instead
-- of a static workspace.library dump of the whole runtimepath.
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { checkThirdParty = false },
      -- lazydev's library also defines `vim`; kept here as a fallback
      -- for lua buffers lazydev doesn't cover.
      diagnostics = { globals = { "vim" } },
    },
  },
})

-- bashls / yamlls run on nvim-lspconfig's defaults (cmd, root markers,
-- filetypes); lua_ls's settings are configured above.
vim.lsp.config("bashls", {})
vim.lsp.config("yamlls", {})

-- Enable each server only when its binary is on PATH, so a host missing
-- one degrades gracefully (the server just doesn't attach) rather than
-- erroring. Binaries come from nix on macOS/Linux and winget/npm/uv on
-- Windows (see .data/packages.yaml). This replaces mason + mason-lspconfig
-- automatic_enable — every server, mason-provided or not, enables here.
local function executable(name)
  return vim.fn.executable(name) == 1
end
local servers = {}
if executable("nil") then
  table.insert(servers, "nil_ls")
end
if executable("pyright-langserver") or executable("pyright") then
  table.insert(servers, "pyright")
end
if executable("ruff") then
  table.insert(servers, "ruff")
end
if executable("rust-analyzer") then
  table.insert(servers, "rust_analyzer")
end
if executable("lua-language-server") then
  table.insert(servers, "lua_ls")
end
if executable("bash-language-server") then
  table.insert(servers, "bashls")
end
if executable("yaml-language-server") then
  table.insert(servers, "yamlls")
end
if #servers > 0 then
  vim.lsp.enable(servers)
end
