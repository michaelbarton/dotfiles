return {
  {
    "mfussenegger/nvim-dap-python",
    config = function()
      -- LazyVim's python extra calls setup("debugpy-adapter"), which expects
      -- mason's debugpy on PATH. Use the ansible-managed nvim venv instead,
      -- which already has debugpy installed (see ansible/tasks/neovim.yml).
      -- The debuggee still runs with the project's own .venv python.
      require("dap-python").setup(vim.fn.expand("~/.venvs/nvim/bin/python"))
      require("dap-python").test_runner = "pytest"
    end,
  },
}
