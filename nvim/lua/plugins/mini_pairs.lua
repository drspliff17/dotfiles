return {
   "nvim-mini/mini.pairs",
   opts = {
      modes = { insert = true, command = true, terminal = true },
   },
   keys = {
      {
         "<leader>cb",
         function()
            local pairs = require("mini.pairs")
            local state = not pairs.config.modes.insert
            pairs.setup({ modes = { insert = state, command = true, terminal = true } })
            vim.notify("mini.pairs insert mode: " .. (state and "ON" or "OFF"))
         end,
         desc = "Toggle mini.pairs insert mode",
      },
   },
}
