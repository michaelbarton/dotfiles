return {
  'Vigemus/iron.nvim',
  version = '*',
  config = function()
    require('iron.core').setup {
      config = {
        repl_definition = {
          sh = {
            -- Can be a table or a function that
            -- returns a table (see below)
            command = { 'zsh' },
          },
          python = {
            command = { 'python3' },
            block_deviders = { '# %%', '#%%' },
          },
        },
      },
    }
  end,
}
