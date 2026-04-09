return {
  "folke/which-key.nvim",
  config = function()
    require("which-key").setup({
      preset = "modern",
      win = {
        padding = { 1, 1 },
        wo = {
          -- winblend = 10,
          border = "rounded",
        },
      },
      layout = {
        spacing = 2,
      },

      -- NOTE: hide like this
      -- spec = {
      -- { "<leader>1", hidden = true },
      -- },
    })
  end,
}
