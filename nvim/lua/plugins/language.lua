return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "fish",
        "json",
        "latex",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "sql",
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
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Prevent r_language_server from attaching to quarto files that don't
        -- have an R project root, since mason-lspconfig maps it to quarto by
        -- default and it errors on Python-only .qmd files.
        r_language_server = {
          root_markers = { "DESCRIPTION", "NAMESPACE", ".Rbuildignore", "*.Rproj" },
          filetypes = { "r", "rmd" },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- injected formats code cells via treesitter language injections;
        -- prettier then hard-wraps prose. prettier is used over mdformat for
        -- quarto because it preserves {{< >}} shortcodes, which mdformat
        -- escapes. Caveat: ::: div content written without surrounding blank
        -- lines gets joined into one paragraph by both tools.
        quarto = { "injected", "prettier" },
        sql = { "sqlfmt" },
        markdown = { "mdformat" },
        vimwiki = { "mdformat" },
      },
      formatters = {
        mdformat = {
          prepend_args = {
            "--wrap",
            "80", -- Wrap text at 80 characters
            "--number", -- Use numbered lists consistently
          },
        },
        prettier = {
          prepend_args = { "--prose-wrap", "always", "--print-width", "80" },
          options = {
            -- prettier can't infer a parser from the .qmd extension
            ft_parsers = { quarto = "markdown" },
          },
        },
        -- Use the ansible-managed venv ruff rather than mason's, which sits
        -- first on PATH inside nvim but lags behind: preserving quarto's `#|`
        -- cell-option comments (instead of rewriting them to `# |`) needs
        -- ruff >= 0.15.17.
        ruff_format = {
          command = vim.fn.expand("~/.venvs/nvim/bin/ruff"),
        },
        -- See:
        -- https://github.com/jmbuhr/quarto-nvim-kickstarter/blob/382b050e13eada7180ad048842386be37e820660/lua/plugins/editing.lua#L29-L81
        injected = {
          options = {
            ignore_errors = false,
            -- Map of treesitter language to file extension
            -- A temporary file name with this extension will be generated during formatting
            -- because some formatters care about the filename.
            lang_to_ext = {
              bash = "sh",
              latex = "tex",
              markdown = "md",
              python = "py",
              vimwiki = "md",
            },
            -- Code cells need an explicit formatter entry here: python files
            -- are normally formatted by the ruff LSP, which the injected
            -- formatter cannot call.
            lang_to_formatters = {
              python = { "ruff_format" },
            },
          },
        },
      },
    },
  },
}
