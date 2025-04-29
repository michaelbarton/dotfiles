-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

-- Insert today's date as a heading in the format ## [[YYYYMMDD]] with two new lines
vim.keymap.set("n", "<leader>id", function()
  local date = os.date("%Y%m%d")
  local heading = "## [[" .. date .. "]]"
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  -- Insert the heading at the current line with two blank lines after it
  vim.api.nvim_buf_set_lines(0, line, line, false, { heading, "", "" })
  -- Move cursor to the first blank line after the heading
  vim.api.nvim_win_set_cursor(0, { line + 2, 0 })
end, { desc = "[I]nsert [D]ate" })

-- Shortcut for searching the wiki
vim.keymap.set("n", "<leader>ws", function()
  local fzf = require("fzf-lua")
  fzf.files({ prompt = "wiki  ", cwd = vim.g.wiki_root })
end, { desc = "[W]iki [S]earch" })

-- Create a new page in the wiki
vim.keymap.set("n", "<leader>wn", function()
  vim.ui.input({ prompt = "Name  " }, function(input)
    if input then
      local timestamp = os.date("%Y%m%d%H%M")
      local filename = string.format("%s/%s_%s.md", vim.g.wiki_root, timestamp, input)
      vim.cmd.edit(filename)
    end
  end)
end, { desc = "[W]iki [N]ew Page" })

vim.keymap.set("n", "<leader>wi", function()
  local fzf = require("fzf-lua")
  fzf.files({
    prompt = "Wiki Files",
    cwd = vim.g.wiki_root,
    actions = {
      -- Override the default selection action
      ["default"] = function(selected)
        -- Get the selected file (should be just one)
        if selected and #selected > 0 then
          local full_path = selected[1]

          -- Extract just the filename from the path
          local filename = full_path:match("([^/\\]+)$")

          -- Create a wiki link format [[filename]] without the file extension
          local link = string.format("[[%s]]", filename:gsub("%.%w+$", ""))

          -- Insert the wiki link at the current cursor position
          vim.api.nvim_put({ link }, "c", true, true)
        end
      end,
    },
  })
end, { noremap = true, silent = true, desc = "[W]iki [I]nsert Link" })
