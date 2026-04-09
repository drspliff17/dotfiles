return {
  "folke/noice.nvim",
  config = function()
    require("noice").setup({
      cmdline = {
        view = "cmdline_popup",
        format = {
          cmdline = { pattern = "^:", icon = "󰞦 ", lang = "vim", title = "Cmd" },
          search_down = { kind = "search", pattern = "^/", icon = "󰞦 ", lang = "regex" },
          search_up = { kind = "search", pattern = "^%?", icon = "󰞦 ", lang = "regex" },
          filter = { pattern = "^:%s*!", icon = "󰞦 ", lang = "bash", title = "Bash" },
          lua = {
            pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" },
            icon = "󰞦 ",
            lang = "lua",
            title = "Lua",
          },
          help = { pattern = "^:%s*he?l?p?%s+", icon = "󰞦 󰘥", title = "Help" },
          input = { view = "cmdline_input", icon = "󰞦 󰥻" },
        },
      },

      presets = {
        bottom_search = true,
      },
    })
  end,
}
