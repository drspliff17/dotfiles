return {
  "Pesterenan/ic10.nvim",
  ft = "ic10",
  config = function()
    require("ic10").setup({
      debug = false -- Set to true to enable event logs
    })
  end,
}
