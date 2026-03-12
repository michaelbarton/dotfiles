return {
  "preservim/vim-pencil",
  ft = { "markdown", "quarto", "vimwiki" },
  init = function()
    vim.g["pencil#textwidth"] = 80
    vim.g["pencil#wrapModeDefault"] = "hard"
    vim.g["pencil#autoformat"] = 1
  end,
}
