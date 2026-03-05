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

-- dbt: extract model name from current file path (e.g., models/staging/stg_orders.sql -> stg_orders)
local function dbt_model_name()
  local filepath = vim.fn.expand("%:t:r")
  if filepath == "" then
    vim.notify("No file open", vim.log.levels.WARN)
    return nil
  end
  return filepath
end

-- dbt: format the current SQL file, then send a dbt command to the terminal
local function dbt_cmd(cmd_template)
  local model = dbt_model_name()
  if not model then
    return
  end

  -- Format with conform (sqlfmt), then save
  require("conform").format({ async = false, lsp_fallback = true })
  vim.cmd("write")

  -- Build the command
  local cmd = string.format(cmd_template, model)

  -- Send to toggleterm (terminal 1)
  local term = require("toggleterm.terminal").get(1)
  if not term then
    term = require("toggleterm.terminal").Terminal:new({ id = 1 })
  end
  if not term:is_open() then
    term:toggle()
  end
  term:send(cmd)
end

-- dbt: find the project root (directory containing dbt_project.yml)
local function dbt_project_root()
  local path = vim.fn.findfile("dbt_project.yml", ".;")
  if path == "" then
    return nil
  end
  return vim.fn.fnamemodify(path, ":p:h")
end

-- dbt: jump to model under cursor from {{ ref('model_name') }} or {{ source('src', 'table') }}
vim.keymap.set("n", "<leader>dg", function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  -- Try to find ref('model') or ref("model") around cursor
  local ref_model = nil
  for start_pos, name, end_pos in line:gmatch("()ref%(['\"]([^'\"]+)['\"]%)()" ) do
    if col >= start_pos and col <= end_pos then
      ref_model = name
      break
    end
  end

  -- Try source('source_name', 'table_name') if no ref found
  local source_name, source_table = nil, nil
  if not ref_model then
    for start_pos, src, tbl, end_pos in line:gmatch("()source%(['\"]([^'\"]+)['\"]%s*,%s*['\"]([^'\"]+)['\"]%)()" ) do
      if col >= start_pos and col <= end_pos then
        source_name, source_table = src, tbl
        break
      end
    end
  end

  if not ref_model and not source_table then
    vim.notify("No ref() or source() under cursor", vim.log.levels.WARN)
    return
  end

  local root = dbt_project_root()
  if not root then
    vim.notify("No dbt_project.yml found", vim.log.levels.WARN)
    return
  end

  -- Search for the model file
  local search_name = ref_model or source_table
  local matches = vim.fn.globpath(root, "**/" .. search_name .. ".sql", false, true)
  if #matches == 0 then
    -- Also try .yml for source definitions
    matches = vim.fn.globpath(root, "**/" .. search_name .. ".yml", false, true)
  end

  if #matches == 1 then
    vim.cmd.edit(matches[1])
  elseif #matches > 1 then
    vim.ui.select(matches, { prompt = "Multiple matches:" }, function(choice)
      if choice then
        vim.cmd.edit(choice)
      end
    end)
  else
    vim.notify("No file found for: " .. search_name, vim.log.levels.WARN)
  end
end, { desc = "[D]bt [G]o to ref/source" })

-- dbt: send a raw command string to toggleterm (used by fzf actions)
local function dbt_cmd_raw(cmd)
  local term = require("toggleterm.terminal").get(1)
  if not term then
    term = require("toggleterm.terminal").Terminal:new({ id = 1 })
  end
  if not term:is_open() then
    term:toggle()
  end
  term:send(cmd)
end

-- dbt: fuzzy model picker — select a model then choose an action
vim.keymap.set("n", "<leader>df", function()
  local root = dbt_project_root()
  if not root then
    vim.notify("No dbt_project.yml found", vim.log.levels.WARN)
    return
  end

  local fzf = require("fzf-lua")
  fzf.files({
    prompt = "dbt model  ",
    cwd = root,
    cmd = "fd -e sql . models",
    actions = {
      -- Default: open the file
      ["default"] = fzf.actions.file_edit,
      -- Ctrl-r: run the selected model
      ["ctrl-r"] = function(selected)
        if selected and #selected > 0 then
          local name = selected[1]:match("([^/]+)%.sql$")
          if name then
            dbt_cmd_raw("dbt run -s " .. name)
          end
        end
      end,
      -- Ctrl-b: build the selected model
      ["ctrl-b"] = function(selected)
        if selected and #selected > 0 then
          local name = selected[1]:match("([^/]+)%.sql$")
          if name then
            dbt_cmd_raw("dbt build -s " .. name)
          end
        end
      end,
      -- Ctrl-t: test the selected model
      ["ctrl-t"] = function(selected)
        if selected and #selected > 0 then
          local name = selected[1]:match("([^/]+)%.sql$")
          if name then
            dbt_cmd_raw("dbt test -s " .. name)
          end
        end
      end,
    },
    fzf_opts = {
      ["--header"] = "enter=open | ctrl-r=run | ctrl-b=build | ctrl-t=test",
      ["--multi"] = true,
    },
  })
end, { desc = "[D]bt [F]ind model (fzf)" })

-- dbt: open the compiled SQL for the current model in a split
vim.keymap.set("n", "<leader>do", function()
  local model = dbt_model_name()
  if not model then
    return
  end
  local root = dbt_project_root()
  if not root then
    vim.notify("No dbt_project.yml found", vim.log.levels.WARN)
    return
  end
  local compiled = vim.fn.globpath(root, "target/compiled/**/" .. model .. ".sql", false, true)
  if #compiled == 0 then
    vim.notify("No compiled SQL found — run dbt compile first", vim.log.levels.WARN)
    return
  end
  vim.cmd("vsplit " .. compiled[1])
  vim.bo.readonly = true
  vim.bo.modifiable = false
end, { desc = "[D]bt [O]pen compiled SQL" })

-- dbt: grep across all models (search for column names, CTEs, etc.)
vim.keymap.set("n", "<leader>d/", function()
  local root = dbt_project_root()
  if not root then
    vim.notify("No dbt_project.yml found", vim.log.levels.WARN)
    return
  end
  require("fzf-lua").grep({ prompt = "dbt grep  ", cwd = root .. "/models" })
end, { desc = "[D]bt search models" })

vim.keymap.set("n", "<leader>dr", function()
  dbt_cmd("dbt run -s %s")
end, { desc = "[D]bt [R]un current model" })

vim.keymap.set("n", "<leader>dR", function()
  dbt_cmd("dbt run -s %s+")
end, { desc = "[D]bt [R]un model + downstream" })

vim.keymap.set("n", "<leader>db", function()
  dbt_cmd("dbt build -s %s")
end, { desc = "[D]bt [B]uild current model (run + test)" })

vim.keymap.set("n", "<leader>dc", function()
  dbt_cmd("dbt compile -s %s")
end, { desc = "[D]bt [C]ompile current model" })

vim.keymap.set("n", "<leader>dt", function()
  dbt_cmd("dbt test -s %s")
end, { desc = "[D]bt [T]est current model" })

vim.keymap.set("n", "<leader>ds", function()
  dbt_cmd("dbt show -s %s")
end, { desc = "[D]bt [S]how preview results" })

-- dbt: run claude agent on current model (quick analysis with sonnet)
vim.keymap.set("n", "<leader>da", function()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    vim.notify("No file open", vim.log.levels.WARN)
    return
  end
  local cmd = string.format(
    'claude -p "Review this dbt model and add brief comments suggesting improvements, potential issues, or best-practice violations. Be concise." --model claude-sonnet-4-6 %s',
    vim.fn.shellescape(filepath)
  )
  dbt_cmd_raw(cmd)
end, { desc = "[D]bt [A]nalyse model (quick)" })

-- dbt: run claude agent on current model (deep analysis with sonnet thinking, cross-reference DB)
-- Compiles the model first, then passes compiled SQL + first 20 rows as extra context
vim.keymap.set("n", "<leader>dA", function()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    vim.notify("No file open", vim.log.levels.WARN)
    return
  end
  local model = dbt_model_name()
  if not model then
    return
  end
  local root = dbt_project_root()
  if not root then
    vim.notify("No dbt_project.yml found", vim.log.levels.WARN)
    return
  end

  -- Build a shell script that:
  -- 1. Compiles the model and captures compiled SQL
  -- 2. Runs dbt show --limit 20 to get sample rows
  -- 3. Feeds everything to claude
  local cmd = string.format(
    [[dbt compile -s %s --quiet && compiled_sql=$(cat $(find %s/target/compiled -name '%s.sql' | head -1) 2>/dev/null) && sample_rows=$(dbt show -s %s --limit 20 2>/dev/null) && claude -p "You have access to a duckdb database. Interrogate the database to understand the schema and data, then cross-reference with this dbt model. Check for: data quality issues, join correctness, missing filters, column type mismatches, and potential improvements. Run queries to validate assumptions.

Here is the compiled SQL:
${compiled_sql}

Here are the first 20 rows returned by this model:
${sample_rows}" --model claude-sonnet-4-6 --thinking %s]],
    model,
    vim.fn.shellescape(root),
    model,
    model,
    vim.fn.shellescape(filepath)
  )
  dbt_cmd_raw(cmd)
end, { desc = "[D]bt [A]nalyse model (deep, DB cross-ref)" })
