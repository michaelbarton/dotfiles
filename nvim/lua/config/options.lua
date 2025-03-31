-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.lazyvim_python_lsp = "basedpyright"

-- Venv for neovim plugins
-- These are managed by ansible in the dotfiles setup
vim.env.PATH = vim.env.PATH .. ":" .. vim.fn.expand("~/.venvs/nvim/bin")
