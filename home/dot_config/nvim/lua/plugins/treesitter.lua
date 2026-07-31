return {
  -- Syntax highlighting and code understanding via AST
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- v1 rewrite; requires nvim 0.11+
    lazy = false, -- main does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      -- The fleet-wide parser manifest lives in lua/config/ts-parsers.lua (the
      -- single source of truth, shared with the chezmoi pre-install script).
      -- Auto-install any missing parser at startup — install() is async and
      -- no-ops parsers already present. The one exception: when the pre-install
      -- script drives a headless install itself it sets TS_PREINSTALL=1, and we
      -- skip here so a second install() in the same nvim can't race the
      -- script's install():wait() on the same parser.
      if vim.env.TS_PREINSTALL ~= "1" then
        -- max_jobs caps concurrent parser downloads. nvim-treesitter's default
        -- (100 → all at once) saturates the network and yields corrupt tarballs
        -- ("Damaged tar archive"); a small cap is reliable and, for the handful
        -- of parsers a startup ever installs, still plenty fast.
        require("nvim-treesitter").install(require("config.ts-parsers"), { max_jobs = 4 })
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
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
