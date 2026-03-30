return {
  "nvim-telescope/telescope.nvim",
  opts = {
    defaults = {
      -- Search hidden files in live_grep, consistent with fd's --hidden flag
      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--hidden",
        "--glob=!.git/",
      },
      -- Remove ./ prefix from fd results in file pickers
      find_command = {
        "fd",
        "--type=f",
        "--hidden",
        "--follow",
        "--exclude=.git",
        "--strip-cwd-prefix",
      },
    },
  },
}
