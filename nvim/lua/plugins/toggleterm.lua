return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    local toggleterm = require("toggleterm")
    local Terminal = require("toggleterm.terminal").Terminal
    local terminal_module = require("toggleterm.terminal")

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

    local role_config = {
      run = { count = 1, direction = "horizontal" },
      test = { count = 2, direction = "horizontal" },
      scratch = { count = 3, direction = "float" },
    }

    local role_order = { "run", "test", "scratch" }
    local managed_terminals = {}
    local last_role = "run"

    local function notify_role(action, role)
      vim.notify(string.format("%s %s terminal", action, role), vim.log.levels.INFO, { title = "ToggleTerm" })
    end

    local function ensure_terminal(role)
      local cfg = role_config[role]
      if not managed_terminals[role] then
        managed_terminals[role] = Terminal:new({
          count = cfg.count,
          direction = cfg.direction,
          hidden = true,
          close_on_exit = false,
        })
      end
      return managed_terminals[role]
    end

    local function open_role(role)
      local term = ensure_terminal(role)
      term:open()
      last_role = role
      notify_role("Focused", role)
      return term
    end

    local function toggle_last_role()
      local term = ensure_terminal(last_role)
      term:toggle()
      notify_role("Toggled", last_role)
    end

    local function close_current_terminal()
      local current_id = vim.b.toggle_number
      if current_id then
        local term = terminal_module.get(current_id)
        if term then
          term:close()
          vim.notify("Closed current terminal", vim.log.levels.INFO, { title = "ToggleTerm" })
          return
        end
      end

      local term = ensure_terminal(last_role)
      if term:is_open() then
        term:close()
        notify_role("Closed", last_role)
      else
        vim.notify("No managed terminal is currently open", vim.log.levels.INFO, { title = "ToggleTerm" })
      end
    end

    local function close_all_terminals()
      local closed = 0
      for _, role in ipairs(role_order) do
        local term = managed_terminals[role]
        if term and term:is_open() then
          term:close()
          closed = closed + 1
        end
      end

      if closed == 0 then
        vim.notify("No managed terminals were open", vim.log.levels.INFO, { title = "ToggleTerm" })
      else
        vim.notify(
          string.format("Closed %d managed terminal(s)", closed),
          vim.log.levels.INFO,
          { title = "ToggleTerm" }
        )
      end
    end

    local function send_to_last_target(mode)
      local term = open_role(last_role)
      local send_mode = mode == "visual" and "visual_selection" or "single_line"
      require("toggleterm").send_lines_to_terminal(send_mode, true, { args = term.id })
      if mode == "visual" then
        notify_role("Sent selection to", last_role)
      else
        notify_role("Sent line to", last_role)
      end
    end

    local function run_just_target()
      local output = vim.fn.systemlist("just --list --unsorted 2>/dev/null")
      if vim.v.shell_error ~= 0 or #output == 0 then
        vim.notify("No justfile found or no targets available", vim.log.levels.WARN)
        return
      end

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
        if not choice then
          return
        end

        local term = open_role("run")
        if term.job_id then
          vim.api.nvim_chan_send(term.job_id, "just " .. choice .. "\n")
          vim.notify("Started just " .. choice .. " in run terminal", vim.log.levels.INFO, { title = "ToggleTerm" })
        else
          vim.notify("Run terminal is not ready yet", vim.log.levels.WARN, { title = "ToggleTerm" })
        end
      end)
    end

    local term_keymaps_group = vim.api.nvim_create_augroup("ToggleTermLocalKeymaps", { clear = true })
    vim.api.nvim_create_autocmd("TermOpen", {
      group = term_keymaps_group,
      pattern = "term://*",
      callback = function(event)
        if vim.bo[event.buf].filetype ~= "toggleterm" then
          return
        end

        local opts = { buffer = event.buf }
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
        -- Route directional moves through vim-tmux-navigator for consistent pane navigation.
        vim.keymap.set("t", "<C-h>", [[<Cmd>TmuxNavigateLeft<CR>]], opts)
        vim.keymap.set("t", "<C-j>", [[<Cmd>TmuxNavigateDown<CR>]], opts)
        vim.keymap.set("t", "<C-k>", [[<Cmd>TmuxNavigateUp<CR>]], opts)
        vim.keymap.set("t", "<C-l>", [[<Cmd>TmuxNavigateRight<CR>]], opts)
        vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
      end,
    })

    vim.keymap.set("n", "<leader>tr", function()
      open_role("run")
    end, { desc = "[T]erminal [R]un" })

    vim.keymap.set("n", "<leader>te", function()
      open_role("test")
    end, { desc = "[T]erminal t[E]st" })

    vim.keymap.set("n", "<leader>ts", function()
      open_role("scratch")
    end, { desc = "[T]erminal [S]cratch" })

    vim.keymap.set("n", "<leader>ta", toggle_last_role, { desc = "[T]erminal toggle l[A]st" })
    vim.keymap.set("n", "<leader>tx", close_current_terminal, { desc = "[T]erminal close current" })
    vim.keymap.set("n", "<leader>tX", close_all_terminals, { desc = "[T]erminal close all" })
    vim.keymap.set("n", "<leader>tl", function()
      send_to_last_target("line")
    end, { desc = "[T]erminal send [L]ine" })
    vim.keymap.set("v", "<leader>tl", function()
      send_to_last_target("visual")
    end, { desc = "[T]erminal send [L]ines" })
    vim.keymap.set("n", "<leader>tj", run_just_target, { desc = "[T]erminal run [J]ust target" })
  end,
  keys = {
    { "<c-\\>", desc = "Toggle terminal" },
    { "<leader>tr", desc = "Open run terminal" },
    { "<leader>te", desc = "Open test terminal" },
    { "<leader>ts", desc = "Open scratch terminal" },
    { "<leader>ta", desc = "Toggle last terminal" },
    { "<leader>tx", desc = "Close current terminal" },
    { "<leader>tX", desc = "Close all terminals" },
    { "<leader>tl", desc = "Send line to terminal" },
    { "<leader>tl", desc = "Send selection to terminal", mode = "v" },
    { "<leader>tj", desc = "Run just target in terminal" },
  },
}
