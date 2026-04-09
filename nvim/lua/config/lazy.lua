-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
   local lazyrepo = "https://github.com/folke/lazy.nvim.git"
   local out = vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "--branch=stable",
      lazyrepo,
      lazypath,
   })
   if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
         { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
         { out, "WarningMsg" },
         { "\nPress any key to exit..." },
      }, true, {})
      vim.fn.getchar()
      os.exit(1)
   end
end
vim.opt.rtp:prepend(lazypath)

-- Colorscheme persistence file
local cs_file = vim.fn.stdpath("config") .. "/last_colorscheme"
local default_cs = "tokyonight"
if vim.fn.filereadable(cs_file) == 0 then
   vim.fn.writefile({ default_cs }, cs_file)
end
local last_cs = vim.fn.readfile(cs_file)[1] or default_cs

-- Setup lazy.nvim
require("lazy").setup({
   spec = {
      { "LazyVim/LazyVim", import = "lazyvim.plugins" },
      { import = "plugins" },

      -- Minimal colorscheme imports
      --{ "sainnhe/sonokai", name = "sonokai", lazy = false, priority = 1000 },
      --{ "SpookySec/vim-spooky", name = "spooky", lazy = false, priority = 1000 },
      --{ "yous/vim-open-color", name = "OpenCol", lazy = false, priority = 1000 },
      --{ "Nequo/palefire-nvim", name = "Palefire", lazy = false, priority = 1000 },
      { "sainnhe/everforest", name = "Everforest", lazy = false, priority = 1000 },

      -- Telescope colorscheme picker, deferred setup
      {
         "nvim-telescope/telescope.nvim",
         dependencies = { "nvim-lua/plenary.nvim" },
         lazy = true, -- load only on keymap
         keys = {
            {
               "<leader>cc",
               function()
                  local telescope = require("telescope")
                  telescope.setup({})

                  local example_text = [[
-- Example syntax
local function hello()
  print("Hello, world!") -- Comment
end

local number = 42
local string = "This is a string"
local boolean = true
local keyword_if = true and false
local table_example = { key = "value" }
]]

                  local actions = require("telescope.actions")
                  local action_state = require("telescope.actions.state")
                  local previewers = require("telescope.previewers")
                  local pickers = require("telescope.pickers")
                  local finders = require("telescope.finders")

                  local original_cs = vim.g.colors_name or "tokyonight"
                  local results = vim.fn.getcompletion("", "color")

                  local picker = pickers.new({}, {
                     prompt_title = "Colorschemes",
                     finder = finders.new_table({ results = results }),
                     previewer = previewers.new_buffer_previewer({
                        define_preview = function(self, entry)
                           vim.schedule(function()
                              if vim.api.nvim_buf_is_valid(self.state.bufnr) then
                                 vim.api.nvim_buf_set_lines(
                                    self.state.bufnr,
                                    0,
                                    -1,
                                    false,
                                    vim.split(example_text, "\n")
                                 )
                                 vim.bo[self.state.bufnr].filetype = "lua"
                                 pcall(vim.cmd, "colorscheme " .. entry.value)
                              end
                           end)
                        end,
                     }),
                     attach_mappings = function(prompt_bufnr, map)
                        actions.select_default:replace(function()
                           local selection = action_state.get_selected_entry()
                           actions.close(prompt_bufnr)
                           vim.cmd.colorscheme(selection.value)
                           vim.fn.writefile({ selection.value }, cs_file)
                        end)

                        map("i", "<Esc>", function()
                           actions.close(prompt_bufnr)
                           vim.cmd.colorscheme(original_cs)
                        end)
                        map("n", "<Esc>", function()
                           actions.close(prompt_bufnr)
                           vim.cmd.colorscheme(original_cs)
                        end)

                        return true
                     end,
                  })

                  picker:find()
               end,
               desc = "Pick colorscheme (persistent with live example)",
            },
         },
      },
   },

   defaults = { lazy = false, version = false },
   install = { colorscheme = { "tokyonight", "catppuccin", "dracula", "habamax" } },
   checker = { enabled = true, notify = false },
   performance = {
      rtp = { disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" } },
   },
})

-- Load last-used colorscheme immediately
vim.cmd.colorscheme(last_cs)

-- :Col command for manual switching
vim.api.nvim_create_user_command("Col", function(opts)
   if opts.args == "" then
      vim.notify("Current colorscheme: " .. (vim.g.colors_name or default_cs), vim.log.levels.INFO)
   else
      local ok = pcall(vim.cmd, "colorscheme " .. opts.args)
      if ok then
         vim.notify("Colorscheme switched to: " .. opts.args, vim.log.levels.INFO)
         vim.fn.writefile({ opts.args }, cs_file)
      else
         vim.notify("Colorscheme not found: " .. opts.args, vim.log.levels.ERROR)
      end
   end
end, {
   nargs = "?",
   complete = function()
      return vim.fn.getcompletion("", "color")
   end,
})
