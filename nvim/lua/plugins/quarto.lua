return {
  "quarto-dev/quarto-nvim",
  ft = { "quarto" },
  opts = {
    cmpSource = {
      enabled = false,
    },
  },
  dependencies = {
    {
      "jmbuhr/otter.nvim",
      opts = {
        completion = {
          enabled = false,
        },
      },
    },
  },
}
