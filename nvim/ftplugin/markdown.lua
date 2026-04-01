vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true

vim.opt_local.foldenable = false
vim.opt_local.conceallevel = 0

-- Hard wrap prose at 80 characters
vim.opt_local.textwidth = 80
vim.opt_local.formatoptions = "tqnl1jr"
vim.opt_local.formatexpr = ""
vim.opt_local.comments = "b:*,b:-,b:+,b:1.,b:a."
vim.opt_local.autoindent = true

-- Soft wrap display for lines that exceed textwidth
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
vim.opt_local.showbreak = "↪ "

vim.b.completion = false
