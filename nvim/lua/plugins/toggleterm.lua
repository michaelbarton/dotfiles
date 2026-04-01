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

    -- Run a just target via a picker
    vim.keymap.set("n", "<leader>tj", function()
      local output = vim.fn.systemlist("just --list --unsorted 2>/dev/null")
      if vim.v.shell_error ~= 0 or #output == 0 then
        vim.notify("No justfile found or no targets available", vim.log.levels.WARN)
        return
      end

      -- Skip the header line ("Available recipes:") and parse target names
      local targets = {}
      for i, line in ipairs(output) do
        if i > 1 then
          local target = line:match("^%s+(%S+)")
          if target then
            table.insert(targets, target)
          end
        end
      end

      vim.ui.select(targets, { prompt = "just target> " }, function(choice)
        if choice then
          require("toggleterm.terminal").Terminal
            :new({ cmd = "just " .. choice, close_on_exit = false, direction = "horizontal" })
            :toggle()
        end
      end)
    end, { desc = "[T]oggle [J]ust target" })

    -- Terminal navigation keymaps
    function _G.set_terminal_keymaps()
      local opts = { buffer = 0 }
      vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
      vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
      vim.keymap.set("t", "<C-h>", [[<Cmd>TmuxNavigateLeft<CR>]], opts)
      vim.keymap.set("t", "<C-j>", [[<Cmd>TmuxNavigateDown<CR>]], opts)
      vim.keymap.set("t", "<C-k>", [[<Cmd>TmuxNavigateUp<CR>]], opts)
      vim.keymap.set("t", "<C-l>", [[<Cmd>TmuxNavigateRight<CR>]], opts)
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
    { "<leader>tj", desc = "Run just target" },
  },
}
