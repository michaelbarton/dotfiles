return {
  "vimwiki/vimwiki",
  init = function()
    vim.g.vimwiki_list = {
      {
        path = "~/Dropbox/wiki/zettel/",
        syntax = "markdown",
        ext = ".md",
      },
    }
  end,
  config = function()
    -- Delete the default <leader>wn mapping when vimwiki filetype is loaded
    local group = vim.api.nvim_create_augroup("VimwikiCustomizations", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "vimwiki",
      group = group,
      callback = function()
        pcall(vim.keymap.del, 'n', '<leader>wn')
      end,
    })
  end,
}
