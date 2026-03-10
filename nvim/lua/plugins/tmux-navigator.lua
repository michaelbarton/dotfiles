return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate left" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate down" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate up" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right" },
  },
}
