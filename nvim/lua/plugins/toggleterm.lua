return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    local toggleterm = require("toggleterm")

    toggleterm.setup({
      -- Terminal window size
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,

      -- Default terminal direction
      direction = "horizontal",

      -- Terminal window settings
      open_mapping = [[<c-\>]], -- Ctrl+\ to toggle terminal
      hide_numbers = true, -- Hide line numbers in terminal
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 2, -- degree of terminal window shading
      start_in_insert = true, -- start terminal in insert mode
      insert_mappings = true, -- allow toggling terminal in insert mode
      persist_size = true,
      close_on_exit = true, -- close terminal when process exits
      shell = vim.o.shell, -- use your default shell
    })

    -- Set up key mappings for terminals
    vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm<CR>", { desc = "[T]oggle [T]erminal" })
    vim.keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", { desc = "[T]oggle [F]loating terminal" })
    vim.keymap.set(
      "n",
      "<leader>tv",
      "<cmd>ToggleTerm direction=vertical<CR>",
      { desc = "[T]oggle [V]ertical terminal" }
    )
    vim.keymap.set(
      "n",
      "<leader>th",
      "<cmd>ToggleTerm direction=horizontal<CR>",
      { desc = "[T]oggle [H]orizontal terminal" }
    )

    -- Send text to terminal
    vim.keymap.set("n", "<leader>tl", function()
      local term_id = vim.v.count > 0 and vim.v.count or 1

      -- Get terminal by ID and toggle it if closed
      local term = require("toggleterm.terminal").get(term_id)
      if term and not term:is_open() then
        term:toggle()
      end

      -- Send the current line
      require("toggleterm").send_lines_to_terminal("single_line", true, { args = term_id })
    end, { desc = "[T]erminal send [L]ine" })

    vim.keymap.set("v", "<leader>ts", function()
      local term_id = vim.v.count > 0 and vim.v.count or 1

      -- Get terminal by ID and toggle it if closed
      local term = require("toggleterm.terminal").get(term_id)
      if term and not term:is_open() then
        term:toggle()
      end

      -- Send the visual selection
      require("toggleterm").send_lines_to_terminal("visual_selection", true, { args = term_id })
    end, { desc = "[T]erminal [S]end visual selection" })

    -- Terminal navigation keymaps
    function _G.set_terminal_keymaps()
      local opts = { buffer = 0 }
      vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
      vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
      vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
      vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
      vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
      vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
      vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
    end

    -- Auto-apply terminal keymaps when opening a terminal
    vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
  end,
  keys = {
    { "<c-\\>", desc = "Toggle terminal" },
    { "<leader>tt", desc = "Toggle terminal" },
    { "<leader>tf", desc = "Toggle floating terminal" },
    { "<leader>tv", desc = "Toggle vertical terminal" },
    { "<leader>th", desc = "Toggle horizontal terminal" },
    { "<leader>ts", desc = "Send visual selection to terminal", mode = "v" },
    { "<leader>tl", desc = "Send line to terminal" },
  },
}
