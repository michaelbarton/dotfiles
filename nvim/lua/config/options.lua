-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Can set this to have type warnings, however this usually creates too much noise
-- vim.g.lazyvim_python_lsp = "basedpyright"

-- Venv for neovim plugins
-- These are managed by ansible in the dotfiles setup
vim.env.PATH = vim.env.PATH .. ":" .. vim.fn.expand("~/.venvs/nvim/bin")

-- Location of wiki files
vim.g.wiki_root = "~/Dropbox/wiki/zettel/"

vim.o.shell = "fish"

-- Global text width and wrapping settings
vim.opt.textwidth = 80
vim.opt.wrap = true

-- Better search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true

-- Better editing
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Performance
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300

-- Better splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Show invisible characters
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
