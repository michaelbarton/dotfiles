-- Trouble - better diagnostics list (v3 API)
return {
  "folke/trouble.nvim",
  cmd = { "Trouble" },
  opts = {
    use_diagnostic_signs = true,
  },
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Document Diagnostics (Trouble)" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace Diagnostics (Trouble)" },
    { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
    { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
  },
}
