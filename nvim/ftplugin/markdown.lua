vim.opt_local.textwidth = 80

-- auto format text as it's being edited
-- c=auto-wrap comments, q=allow gq, l=don't break existing long lines, n=format lists
vim.opt_local.formatoptions:append("cqln")

-- recognize asterisk as bullets
-- https://unix.stackexchange.com/a/31348
vim.opt_local.formatlistpat:append([[\|^\\*\s*]])

-- Maintain indenting of paragraphs in the text
vim.opt_local.autoindent = true

-- Use two spaces for tabs
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true

-- disable folding and conceal (LazyVim markdown extra uses render-markdown.nvim)
vim.opt_local.foldenable = false
vim.opt_local.conceallevel = 0
