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
  require("telescope.builtin").find_files({ prompt_title = "Wiki", cwd = vim.g.wiki_root })
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
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  require("telescope.builtin").find_files({
    prompt_title = "Wiki Insert Link",
    cwd = vim.g.wiki_root,
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry then
          local filename = entry[1]:match("([^/\\]+)$")
          local link = string.format("[[%s]]", filename:gsub("%.%w+$", ""))
          vim.api.nvim_put({ link }, "c", true, true)
        end
      end)
      return true
    end,
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

  -- Send to toggleterm (terminal 1), then return focus to the code window
  local prev_win = vim.api.nvim_get_current_win()
  local term = require("toggleterm.terminal").get(1)
  if not term then
    term = require("toggleterm.terminal").Terminal:new({ id = 1 })
  end
  if not term:is_open() then
    term:toggle()
  end
  term:send(cmd)
  vim.api.nvim_set_current_win(prev_win)
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

-- dbt: send a raw command string to toggleterm (used by picker actions)
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

  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  require("telescope.builtin").find_files({
    prompt_title = "dbt model (enter=open, C-r=run, C-b=build, C-t=test)",
    cwd = root,
    search_dirs = { "models" },
    find_command = { "fd", "-e", "sql" },
    attach_mappings = function(prompt_bufnr, map)
      local function get_model_name()
        local entry = action_state.get_selected_entry()
        if entry then
          return entry[1]:match("([^/]+)%.sql$")
        end
      end
      map("i", "<C-r>", function()
        local name = get_model_name()
        actions.close(prompt_bufnr)
        if name then dbt_cmd_raw("uv run dbt run -s " .. name) end
      end)
      map("i", "<C-b>", function()
        local name = get_model_name()
        actions.close(prompt_bufnr)
        if name then dbt_cmd_raw("uv run dbt build -s " .. name) end
      end)
      map("i", "<C-t>", function()
        local name = get_model_name()
        actions.close(prompt_bufnr)
        if name then dbt_cmd_raw("uv run dbt test -s " .. name) end
      end)
      return true
    end,
  })
end, { desc = "[D]bt [F]ind model" })

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
  require("telescope.builtin").live_grep({ prompt_title = "dbt grep", cwd = root .. "/models" })
end, { desc = "[D]bt search models" })

vim.keymap.set("n", "<leader>dr", function()
  dbt_cmd("uv run dbt run -s %s")
end, { desc = "[D]bt [R]un current model" })

vim.keymap.set("n", "<leader>dR", function()
  dbt_cmd("uv run dbt run -s %s+")
end, { desc = "[D]bt [R]un model + downstream" })

vim.keymap.set("n", "<leader>db", function()
  dbt_cmd("uv run dbt build -s %s")
end, { desc = "[D]bt [B]uild current model (run + test)" })

vim.keymap.set("n", "<leader>dc", function()
  dbt_cmd("uv run dbt compile -s %s")
end, { desc = "[D]bt [C]ompile current model" })

vim.keymap.set("n", "<leader>dt", function()
  dbt_cmd("uv run dbt test -s %s")
end, { desc = "[D]bt [T]est current model" })

vim.keymap.set("n", "<leader>ds", function()
  dbt_cmd("uv run dbt show -s %s")
end, { desc = "[D]bt [S]how preview results" })

-- dbt: preview sample rows in a horizontal split
vim.keymap.set("n", "<leader>dp", function()
  local model = dbt_model_name()
  if not model then
    return
  end
  vim.notify("Fetching preview for " .. model .. "...", vim.log.levels.INFO)
  local cmd = { "uv", "run", "dbt", "show", "-s", model, "--limit", "20" }
  local output = {}
  vim.fn.jobstart(cmd, {
    cwd = dbt_project_root(),
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(output, data)
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code ~= 0 then
          vim.notify("dbt show failed (exit " .. exit_code .. ")", vim.log.levels.ERROR)
          return
        end
        -- Trim trailing empty lines
        while #output > 0 and output[#output] == "" do
          table.remove(output)
        end
        if #output == 0 then
          vim.notify("No rows returned", vim.log.levels.WARN)
          return
        end
        -- Open a scratch buffer in a horizontal split
        vim.cmd("botright new")
        local buf = vim.api.nvim_get_current_buf()
        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].bufhidden = "wipe"
        vim.bo[buf].swapfile = false
        vim.bo[buf].filetype = "sql"
        vim.api.nvim_buf_set_name(buf, "dbt-preview://" .. model)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
        vim.bo[buf].modifiable = false
        -- Resize to fit content (max 20 lines)
        local height = math.min(#output, 20)
        vim.api.nvim_win_set_height(0, height)
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
      end)
    end,
  })
end, { desc = "[D]bt [P]review model rows" })

-- dbt: show model output as CSV piped into visidata
vim.keymap.set("n", "<leader>dv", function()
  local model = dbt_model_name()
  if not model then
    return
  end
  local root = dbt_project_root()
  if not root then
    vim.notify("No dbt_project.yml found", vim.log.levels.WARN)
    return
  end
  require("conform").format({ async = false, lsp_fallback = true })
  vim.cmd("write")
  local prev_win = vim.api.nvim_get_current_win()
  local json_to_csv = [[python3 -c "
import sys, json, csv
raw = sys.stdin.read()
for line in raw.splitlines():
    try:
        obj = json.loads(line)
    except json.JSONDecodeError:
        continue
    preview = None
    if 'data' in obj and 'preview' in obj['data']:
        preview = obj['data']['preview']
    elif 'results' in obj:
        preview = obj['results'][0].get('preview')
    elif 'preview' in obj:
        preview = obj['preview']
    if preview:
        if isinstance(preview, str):
            preview = json.loads(preview)
        w = csv.DictWriter(sys.stdout, fieldnames=preview[0].keys())
        w.writeheader()
        w.writerows(preview)
        break
"]]
  local cmd = "cd " .. root .. " && uv run dbt show -s " .. model .. " --limit 500 --output json --log-format json | " .. json_to_csv .. " | vd -f csv"
  require("toggleterm.terminal").Terminal
    :new({
      cmd = cmd,
      close_on_exit = true,
      on_exit = function()
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(prev_win) then
            vim.api.nvim_set_current_win(prev_win)
          end
        end)
      end,
    })
    :toggle()
end, { desc = "[D]bt [V]isidata preview" })

-- dbt: read a prompt template from nvim/prompts/ and substitute {{key}} placeholders
local function dbt_load_prompt(name, vars)
  local prompt_dir = vim.fn.stdpath("config") .. "/prompts/"
  local path = prompt_dir .. name .. ".md"
  local lines = vim.fn.readfile(path)
  if #lines == 0 then
    vim.notify("Prompt not found: " .. path, vim.log.levels.ERROR)
    return nil
  end
  local prompt = table.concat(lines, "\n")
  for key, value in pairs(vars or {}) do
    prompt = prompt:gsub("{{" .. key .. "}}", value)
  end
  return prompt
end

-- dbt: run claude agent on current model (quick analysis with sonnet)
-- Replaces buffer contents with the file + inline SQL comments
vim.keymap.set("n", "<leader>da", function()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    vim.notify("No file open", vim.log.levels.WARN)
    return
  end
  local prompt = dbt_load_prompt("dbt_quick_analysis", {})
  if not prompt then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()

  vim.notify("Running quick analysis...", vim.log.levels.INFO)

  local cmd = { "claude", "-p", prompt, "--model", "claude-sonnet-4-6", filepath }
  local output = {}
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        output = data
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code ~= 0 then
          vim.notify("claude exited with code " .. exit_code, vim.log.levels.ERROR)
          return
        end
        -- Remove trailing empty strings from jobstart output
        while #output > 0 and output[#output] == "" do
          table.remove(output)
        end
        if #output == 0 then
          vim.notify("No output from claude", vim.log.levels.WARN)
          return
        end
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
        vim.notify("Inline comments added — review and :w to save, or :u to undo", vim.log.levels.INFO)
      end)
    end,
  })
end, { desc = "[D]bt [A]nalyse model (quick)" })

-- dbt: open interactive claude session in a new tmux window with compiled SQL + sample rows as context
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

  -- Open a new tmux window that compiles, gathers context, then starts interactive claude
  local prompt_path = vim.fn.stdpath("config") .. "/prompts/dbt_deep_analysis.md"
  local cmd = string.format(
    [[tmux new-window -n 'dbt:%s' ']]
      .. [[uv run dbt compile -s %s --quiet ]]
      .. [[&& compiled_sql=$(cat $(find %s/target/compiled -name "%s.sql" | head -1) 2>/dev/null) ]]
      .. [[&& sample_rows=$(uv run dbt show -s %s --limit 20 2>/dev/null) ]]
      .. [[&& prompt=$(sed -e "s|{{compiled_sql}}|${compiled_sql}|g" -e "s|{{sample_rows}}|${sample_rows}|g" %s) ]]
      .. [[&& claude --model claude-sonnet-4-6 --thinking --prompt "${prompt}" %s ]]
      .. [[|| read -p "Press enter to close..."']],
    model,
    model,
    vim.fn.shellescape(root),
    model,
    model,
    vim.fn.shellescape(prompt_path),
    vim.fn.shellescape(filepath)
  )
  vim.fn.system(cmd)
  vim.notify("Opened interactive claude session in tmux window 'dbt:" .. model .. "'", vim.log.levels.INFO)
end, { desc = "[D]bt [A]nalyse model (interactive)" })
