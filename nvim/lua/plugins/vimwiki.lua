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
}
