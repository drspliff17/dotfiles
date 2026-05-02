return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.explorer = opts.explorer or {}
    opts.explorer.enabled = false

    local dashboard_config = require("config.my_dashboard_config")

    opts.dashboard = opts.dashboard or {}
    opts.dashboard.enabled = true
    opts.dashboard.preset = opts.dashboard.preset or {}

    opts.dashboard.preset.header = dashboard_config.dashboard_header

    opts.dashboard.preset.keys = {
      { icon = "󰞦  ", key = "s", desc = "Restore Session", section = "session" },
      { icon = "󰞦  ", key = "l", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
      { icon = "󰞦  ", key = "q", desc = "Quit", action = ":qa" },
    }

    opts.scratch = opts.scratch or {}
    opts.scratch.minimal = true
  end,

  keys = {
    { "<leader>e", false },
    { "<leader>E", false },
    { "<leader>fe", false },
    { "<leader>fE", false },
    { "<leader>S", false },
    { "<leader>.", false },
  },
}
