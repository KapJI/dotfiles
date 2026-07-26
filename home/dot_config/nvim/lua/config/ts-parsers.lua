-- Fleet-wide treesitter parser manifest — the single source of truth for which
-- parsers get installed. Required by both the nvim-treesitter plugin config
-- (lua/plugins/treesitter.lua, which install()s these at startup) and the
-- chezmoi pre-install script (.chezmoiscripts/unix/after_90), which
-- install():wait()s them so a fresh machine finishes compiling during
-- `chezmoi apply` instead of on the first interactive nvim launch.
--
-- Parsers are per-machine compiled artifacts in stdpath("data")/site/parser —
-- chezmoi never sees them, so this list is the only thing that syncs them
-- across machines. After a manual `:TSInstall foo`, add foo here too or the
-- next machine silently falls back to regex highlighting.
--
-- (tmux is deliberately absent: its .so on older machines is a dead leftover
-- from the master branch — the main-branch registry doesn't support it and
-- install() warns on unknown names.)
return {
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
}
