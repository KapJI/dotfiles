-- :MasonSuggest — manual, on-demand picker for filetype-relevant mason packages.
-- Opens an fzf-lua multi-select listing the recommended LSPs / formatters /
-- linters for the current buffer's filetype, with install status. TAB selects
-- multiple, ENTER runs :MasonInstall on the picks.
return {
  {
    "mason-org/mason.nvim",
    optional = true, -- piggyback on the existing mason spec
    keys = {
      { "<leader>cM", "<cmd>MasonSuggest<cr>", desc = "Mason: suggest tools for current filetype" },
    },
    init = function()
      local recommendations = {
        lua        = { "lua-language-server", "stylua" },
        python     = { "pyright", "ruff" },
        sh         = { "bash-language-server", "shellcheck", "shfmt" },
        bash       = { "bash-language-server", "shellcheck", "shfmt" },
        zsh        = { "shellcheck", "shfmt" },
        yaml       = { "yaml-language-server", "yamllint", "prettier" },
        json       = { "json-lsp", "prettier" },
        jsonc      = { "json-lsp", "prettier" },
        markdown   = { "markdownlint-cli2", "prettier" },
        nix        = { "nil", "nixpkgs-fmt" },
        go         = { "gopls", "gofumpt" },
        rust       = { "rust-analyzer" },
        toml       = { "taplo" },
        dockerfile = { "dockerfile-language-server", "hadolint" },
        terraform  = { "terraform-ls" },
        typescript = { "typescript-language-server", "prettier", "eslint_d" },
        javascript = { "typescript-language-server", "prettier", "eslint_d" },
        html       = { "html-lsp", "prettier" },
        css        = { "css-lsp", "prettier" },
      }

      vim.api.nvim_create_user_command("MasonSuggest", function()
        local ft = vim.bo.filetype
        local pkgs = recommendations[ft]
        if not pkgs or #pkgs == 0 then
          vim.notify(("No mason suggestions for filetype %q"):format(ft),
            vim.log.levels.WARN, { title = "MasonSuggest" })
          return
        end

        local ok, registry = pcall(require, "mason-registry")
        if not ok then
          vim.notify("mason-registry not available", vim.log.levels.ERROR,
            { title = "MasonSuggest" })
          return
        end

        local items = {}
        for _, name in ipairs(pkgs) do
          if registry.has_package(name) then
            local tag = registry.is_installed(name) and "  [installed]" or "  [missing]"
            table.insert(items, ("%-32s%s"):format(name, tag))
          end
        end
        if #items == 0 then
          vim.notify("No matching mason packages found", vim.log.levels.WARN,
            { title = "MasonSuggest" })
          return
        end

        require("fzf-lua").fzf_exec(items, {
          prompt   = ("Mason / %s > "):format(ft),
          winopts  = { title = " MasonSuggest ", title_pos = "center", height = 0.4, width = 0.6 },
          fzf_opts = { ["--multi"] = "", ["--header"] = "TAB to multi-select, ENTER to :MasonInstall" },
          actions  = {
            ["default"] = function(selected)
              if not selected or #selected == 0 then return end
              local to_install = {}
              for _, line in ipairs(selected) do
                local name = line:match("^(%S+)")
                local installed = line:find("%[installed%]")
                if name and not installed then
                  table.insert(to_install, name)
                end
              end
              if #to_install == 0 then
                vim.notify("All selected packages are already installed",
                  vim.log.levels.INFO, { title = "MasonSuggest" })
                return
              end
              vim.cmd("MasonInstall " .. table.concat(to_install, " "))
            end,
          },
        })
      end, { desc = "Suggest mason packages for current filetype" })
    end,
  },
}
