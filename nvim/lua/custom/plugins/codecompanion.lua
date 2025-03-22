return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('codecompanion').setup {
      adapters = {
        qwern = function()
          return require('codecompanion.adapters').extend('ollama', {
            name = 'qwern',
            schema = {
              model = {
                default = 'qwen2.5-coder:14b',
              },
            },
          })
        end,
      },
      strategies = {
        chat = {
          adapter = 'qwern',
        },
        inline = {
          adapter = 'qwern',
        },
        agent = {
          adapter = 'qwern',
        },
      },
    }
  end,
}
