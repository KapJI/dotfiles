-- chezmoi syntax highlighting via alker0/chezmoi.vim.
-- The plugin detects files inside the chezmoi source dir, strips .tmpl, and
-- composes <host-language>.chezmoitmpl for syntax. The single override below
-- fixes .chezmoiignore / .chezmoiremove which the plugin lands on `conf`
-- instead of `gitignore` (the actual format chezmoi uses).
return {
  {
    "alker0/chezmoi.vim",
    lazy = false,
    init = function()
      vim.g["chezmoi#use_tmp_buffer"] = 1
      vim.g["chezmoi#source_dir_path"] = vim.fn.expand("~/.local/share/chezmoi/home")

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "conf.chezmoitmpl",
        callback = function(args)
          local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":t")
          if name == ".chezmoiignore" or name == ".chezmoiremove" then
            vim.bo[args.buf].filetype = "gitignore.chezmoitmpl"
          end
        end,
      })
    end,
  },
}
