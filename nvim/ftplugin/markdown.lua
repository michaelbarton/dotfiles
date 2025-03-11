-- Disable for the time being. Want to disable for vimwiki files
vim.opt_local.textwidth = 79

-- auto format text as it's being edited
-- n=format lists
vim.opt_local.formatoptions:append 'cqln'

-- recognize asterisk as bullets
-- https://unix.stackexchange.com/a/31348
vim.opt_local.formatlistpat:append [[\|^\\*\s*]]

-- Maintain indenting of paragraphs in the text
vim.opt_local.autoindent = true

-- Use two spaces for tabs
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true

-- support front matter of various format
vim.g.vim_markdown_frontmatter = 1 -- for YAML format
vim.g.vim_markdown_toml_frontmatter = 1 -- for TOML format
vim.g.vim_markdown_json_frontmatter = 1 -- for JSON format

-- disable header folding
vim.g.vim_markdown_folding_disabled = 1

-- do not use conceal feature
vim.g.vim_markdown_conceal = 0

vim.g.vim_markdown_auto_insert_bullets = 0
vim.g.vim_markdown_new_list_item_indent = 0
