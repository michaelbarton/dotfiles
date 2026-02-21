-- Disable unused language providers to remove checkhealth warnings
-- These providers are optional and not needed for most workflows

-- Disable Node.js provider if not using Node.js plugins
-- Uncomment if you need Node.js provider:
-- vim.cmd("npm install -g neovim")
vim.g.loaded_node_provider = 0

-- Disable Perl provider (rarely used)
vim.g.loaded_perl_provider = 0

-- Disable Ruby provider if not using Ruby plugins
-- Uncomment if you need Ruby provider:
-- vim.cmd("gem install neovim")
vim.g.loaded_ruby_provider = 0

-- Python provider is useful for some plugins
-- To enable, run: pip3 install neovim
-- For now, we'll leave it enabled as it's commonly used
-- vim.g.loaded_python3_provider = 0