function _G.get_oil_winbar()
   local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
   local dir = require("oil").get_current_dir(bufnr)
   if dir then
      return "[ " .. vim.fn.fnamemodify(dir, ":~") .. " ]"
   else
      return "[ " .. vim.api.nvim_buf_get_name(0) .. " ]"
   end
end

return {
   "stevearc/oil.nvim",

   ---@module 'oil'
   ---@type oil.SetupOpts
   opts = {
      columns = {
         { "size", align = "left", highlight = "OilHidden" },
         "icon",
      },

      win_options = {
         wrap = true,
         winbar = "%!v:lua.get_oil_winbar()",
      },

      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      use_default_keymaps = false,

      view_options = {
         show_hidden = true,
         natural_order = "fast",
         is_always_hidden = function(name, _)
            return name == ".." or name == ".git"
         end,
      },

      float = {
         padding = 2,
         max_width = 0.4,
         max_height = 0.4,
         border = "bold",
         win_options = {
            winblend = 0,
         },
         get_win_title = function(_)
            return "[ Oil ]"
         end,
         preview_split = "auto",
         override = function(conf)
            return conf
         end,
      },

      -- Keybinds when inside Oil buffer
      keymaps = {
         ["g?"] = { "actions.show_help", mode = "n" },

         ["<CR>"] = "actions.select",
         ["<C-j>"] = { "actions.select", mode = "n" },
         ["<C-k>"] = { "actions.parent", mode = "n" },

         ["<C-s>"] = { "actions.select", opts = { vertical = true } },
         ["<C-h>"] = { "actions.select", opts = { horizontal = true } },

         ["<C-p>"] = "actions.preview",

         ["-"] = { "actions.close", mode = "n" },
         ["<C-c>"] = { "actions.close", mode = "n" },
         ["<C-q>"] = { "actions.close", mode = "n" },

         ["<C-r>"] = "actions.refresh",

         ["_"] = { "actions.open_cwd", mode = "n" },

         ["`"] = { "actions.cd", mode = "n" },

         ["gs"] = { "actions.change_sort", mode = "n" },
         ["g."] = { "actions.toggle_hidden", mode = "n" },
         ["g\\"] = { "actions.toggle_trash", mode = "n" },
      },
   },
   dependencies = { { "nvim-mini/mini.icons", opts = {} } },
   lazy = false,
}
