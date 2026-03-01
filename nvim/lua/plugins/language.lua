return {
  {
    "R-nvim/R.nvim",
    -- TODO: Remove this build workaround once https://github.com/R-nvim/R.nvim/issues/466 is
    -- fixed and merged to main, then advance past that commit with `:Lazy update R.nvim`.
    -- The upstream bug: check_rout_parser() calls vim.uv.chdir() into resources/tree-sitter-rout
    -- but early `return` on build failure skips the chdir(cwdir) restore, leaving nvim stuck in
    -- the plugin directory. Root cause is that the tree-sitter-rout submodule gitlink is absent
    -- from older pinned commits, so `git submodule update` is a no-op and grammar.js is missing.
    -- Workaround: clone the source directly so the build succeeds and cwd is properly restored.
    -- Removal check: delete this block, run `make nvim-check`, confirm PASS [R]: clean startup.
    build = function()
      local target = vim.fn.stdpath("data") .. "/lazy/R.nvim/resources/tree-sitter-rout"
      if vim.fn.filereadable(target .. "/grammar.js") == 0 then
        vim.fn.system({ "rm", "-rf", target })
        vim.fn.system({ "git", "clone", "https://github.com/R-nvim/tree-sitter-rout", target })
      end
    end,
  },
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
