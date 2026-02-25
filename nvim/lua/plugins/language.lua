return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "fish",
        "html",
        "javascript",
        "json",
        "latex",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "vim",
        "yaml",
      },
    },
    init = function()
      -- Strip invalid node types from vim highlights query so it works
      -- with the tree-sitter-vim parser bundled in older nvim versions.
      -- See: https://github.com/nvim-treesitter/nvim-treesitter/issues/8369
      local ok = pcall(vim.treesitter.query.get, "vim", "highlights")
      if ok then return end

      local lang_ok, lang = pcall(vim.treesitter.language.inspect, "vim")
      if not lang_ok then return end

      local valid = {}
      for _, s in ipairs(lang.symbols) do
        valid[s[1]] = true
      end

      local files = vim.api.nvim_get_runtime_file("queries/vim/highlights.scm", true)
      local lines = {}
      for _, file in ipairs(files) do
        local f = io.open(file, "r")
        if f then
          for line in f:lines() do
            local node = line:match('^%s*"([^"]+)"%s*$')
            if not node or valid[node] then
              table.insert(lines, line)
            end
          end
          f:close()
        end
      end

      if #lines > 0 then
        pcall(vim.treesitter.query.set, "vim", "highlights", table.concat(lines, "\n"))
      end
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "prettier", "prettierd" } },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        quarto = { "injected" },
        sql = { "sqlfmt" },
        markdown = { "mdformat" },
        vimwiki = { "mdformat" },
      },
      -- Configure mdformat with text wrapping and formatting options
      formatters = {
        mdformat = {
          prepend_args = {
            "--wrap", "80",    -- Wrap text at 80 characters
            "--number",        -- Use numbered lists consistently
          },
        },
      },
      -- See:
      -- https://github.com/jmbuhr/quarto-nvim-kickstarter/blob/382b050e13eada7180ad048842386be37e820660/lua/plugins/editing.lua#L29-L81
      injected = {
        -- Set the options field
        options = {
          -- Set to true to ignore errors
          ignore_errors = false,
          -- Map of treesitter language to file extension
          -- A temporary file name with this extension will be generated during formatting
          -- because some formatters care about the filename.
          lang_to_ext = {
            bash = "sh",
            javascript = "js",
            latex = "tex",
            markdown = "md",
            python = "py",
            r = "r",
            typescript = "ts",
            vimwiki = "md",
          },
          -- Map of treesitter language to formatters to use
          -- (defaults to the value from formatters_by_ft)
          lang_to_formatters = {},
        },
      },
    },
  },
}
