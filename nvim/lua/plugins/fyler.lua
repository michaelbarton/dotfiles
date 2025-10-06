-- Fyler file manager configuration
return {
  {
    "A7Lavinraj/fyler.nvim",
    dependencies = {
      "nvim-mini/mini.icons", -- Using mini.icons as recommended
    },
    branch = "stable", -- Use stable branch for reliability
    keys = {
      {
        "<leader>fe",
        function()
          require("fyler").open()
        end,
        desc = "Open Fyler",
      },
      {
        "<leader>fE",
        function()
          require("fyler").open({ dir = vim.fn.expand("%:p:h") })
        end,
        desc = "Open Fyler (current file dir)",
      },
      {
        "<leader>e",
        function()
          require("fyler").open()
        end,
        desc = "File Explorer (Fyler)",
      },
    },
    opts = {
      close_on_select = false,
      default_explorer = true,
      icon_provider = "mini_icons",
      track_current_buffer = true,
      win = {
        kind = "split_left_most",
        kind_presets = {
          split_left_most = {
            width = "0.2rel",
          },
        },
      },
      mappings = {
        ["q"] = "CloseView",
        ["<Esc>"] = "CloseView",
        ["<CR>"] = "Select",
        ["l"] = "Select",
        ["<C-t>"] = "SelectTab",
        ["|"] = "SelectVSplit",
        ["-"] = "SelectSplit",
        ["^"] = "GotoParent",
        ["="] = "GotoCwd",
        ["."] = "GotoNode",
        ["#"] = "CollapseAll",
        ["<BS>"] = "CollapseNode",
        ["h"] = "CollapseNode",
      },
      git_status = {
        enabled = true,
      },
    },
  },
}

