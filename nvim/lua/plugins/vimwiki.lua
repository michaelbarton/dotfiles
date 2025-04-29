return {
  "vimwiki/vimwiki",
  keys = {
    -- disable the keymap to create new pages
    {"<leader>wn", false},
  },
  init = function()
    vim.g.vimwiki_list = {
      {
        path = "~/Dropbox/wiki/zettel/",
        syntax = "markdown",
        ext = ".md",
      },
    }
  end,
}
