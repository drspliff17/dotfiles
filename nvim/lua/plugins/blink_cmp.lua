return {

  "saghen/blink.cmp",
  -- Configurations
  opts = {
    cmdline = {
      keymap = { preset = "inherit" },
      completion = { menu = { auto_show = true } },
    },

    -- Completion Config
    completion = {

      menu = { auto_show = true },

      list = {
        selection = { preselect = false, auto_insert = false },
      },

      ghost_text = {
        enabled = true,
        show_with_selection = true,
        show_without_selection = false,
        show_with_menu = true,
        show_without_menu = false,
      },
    },

    -- Keymap Config
    keymap = {
      preset = "none",
      ["<C-c>"] = {
        function(cmp)
          cmp.show({ providers = { "snippets" } })
        end,
      },
      ["<C-v>"] = { "cancel", "fallback" },
      ["<C-e>"] = { "show", "show_documentation", "hide_documentation", "fallback" },
      ["<Tab>"] = { "select_and_accept", "fallback" },
      ["<C-z>"] = { "select_prev", "fallback" },
      ["<C-x>"] = { "select_next", "fallback" },
    },
  },
}
