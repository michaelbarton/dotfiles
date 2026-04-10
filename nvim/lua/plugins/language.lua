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
            latex = "tex",
            markdown = "md",
            python = "py",
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
