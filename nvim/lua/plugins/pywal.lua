return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "pywal",
    },
  },
  {
    "AlphaTechnolog/pywal.nvim",
    name = "pywal",
    lazy = false,
    priority = 1000,
    config = function()
      require("pywal").setup()
    end,
  },
}
