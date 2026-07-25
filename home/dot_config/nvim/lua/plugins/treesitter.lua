return {
  -- Syntax highlighting and code understanding via AST
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- v1 rewrite; requires nvim 0.11+
    lazy = false, -- main does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      -- Fleet-wide parser manifest. Parsers are per-machine compiled
      -- artifacts in stdpath("data")/site/parser — chezmoi never sees
      -- them, so this list is the only thing that syncs them across
      -- machines. After a manual `:TSInstall foo`, add foo here too or
      -- the next machine silently falls back to regex highlighting.
      -- install() is async and no-ops for already-installed parsers.
      -- (tmux is deliberately absent: its .so on older machines is a
      -- dead leftover from the master branch — the main-branch registry
      -- doesn't support it and install() warns on unknown names.)
      require("nvim-treesitter").install({
        "bash",
        "c",
        "cmake",
        "cpp",
        "css",
        "csv",
        "dockerfile",
        "dot",
        "dtd",
        "editorconfig",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "go",
        "gomod",
        "hcl",
        "html",
        "ini",
        "javascript",
        "jinja",
        "jinja_inline",
        "json",
        "lua",
        "luadoc",
        "make",
        "markdown",
        "markdown_inline",
        "nix",
        "powershell",
        "proto",
        "python",
        "query",
        "regex",
        "requirements",
        "rst",
        "rust",
        "sql",
        "ssh_config",
        "starlark",
        "strace",
        "terraform",
        "toml",
        "tsv",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      })

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          if not pcall(vim.treesitter.start, args.buf) then
            return
          end
          -- Only take over 'indentexpr' when the parser ships an indents
          -- query. Several installed parsers (make, rst, git_config, vim,
          -- dtd, jinja.html) have none, and the treesitter indentexpr then
          -- degrades to a no-op that clobbers the filetype's native indent
          -- (make's significant tabs, rst list continuations). Leave those.
          local ft = vim.bo[args.buf].filetype
          local lang = vim.treesitter.language.get_lang(ft) or ft
          if vim.treesitter.query.get(lang, "indents") then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
