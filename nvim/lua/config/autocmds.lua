-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("FileType", {
   pattern = "gml",
   callback = function()
      vim.opt_local.foldmethod = "marker"
      vim.opt_local.foldmarker = "#region,#endregion"
   end,
})

vim.filetype.add({
   extension = {
      gd = "gdscript",
      gdshader = "gdshader",
   },
})

vim.api.nvim_create_autocmd("FileType", {
   group = vim.api.nvim_create_augroup("local_help_buf_changes", {}),
   pattern = "help",
   callback = function()
      vim.cmd("wincmd L")
      vim.api.nvim_win_set_height(0, 59)
      vim.api.nvim_win_set_width(0, 90)
      vim.opt_local.wrap = true
      vim.opt_local.linebreak = true
      vim.opt_local.breakindent = true
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      vim.opt_local.signcolumn = "no"
   end,
})

vim.api.nvim_create_autocmd("FileType", {
   group = vim.api.nvim_create_augroup("no_auto_comment_extension", {}),
   callback = function()
      vim.opt_local.formatoptions:remove({ "c", "r", "o" })
   end,
})

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
   group = vim.api.nvim_create_augroup("manage_cursorline_on_active_window", { clear = true }),
   callback = function()
      vim.opt_local.cursorline = true
   end,
})

vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
   group = "manage_cursorline_on_active_window",
   callback = function()
      vim.opt_local.cursorline = false
   end,
})
