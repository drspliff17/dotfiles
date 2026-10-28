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

vim.api.nvim_create_autocmd("FileType", {
  pattern = "odin",
  callback = function()
    vim.opt_local.foldmethod = "marker"
    vim.opt_local.foldmarker = "{,}"
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

-- Manage cursorline on active/inactive buffers
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

-- Auto Term when moving to a.. terminal..
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = vim.api.nvim_create_augroup("auto_enter_term_mode_on_move_to_terminal", { clear = true }),
  pattern = "term://*",
  callback = function()
    vim.cmd("startinsert")
  end,
})

-- Responsive Terminal Placement on Resize
-- TODO: Figure out why it doesnt behave when i close a split
local resize_pending = false
vim.api.nvim_create_autocmd({ "VimResized", "WinResized", "TabEnter" }, {
  group = vim.api.nvim_create_augroup("ResponsiveTerminals", { clear = true }),
  callback = function()
    if resize_pending then
      return
    end
    resize_pending = true

    vim.schedule(function()
      resize_pending = false

      local current_win = vim.api.nvim_get_current_win()
      local focused_term

      for _, term in ipairs(Snacks.terminal.list()) do
        local source = term.opts.win

        if
          term:win_valid()
          and term.opts.relative == "win"
          and source
          and vim.api.nvim_win_is_valid(source)
          and vim.api.nvim_win_get_tabpage(term.win) == vim.api.nvim_get_current_tabpage()
          and (term.opts.position == "right" or term.opts.position == "bottom")
        then
          local width = vim.api.nvim_win_get_width(source)
          if term.opts.position == "right" then
            width = width + vim.api.nvim_win_get_width(term.win) + 1
          end

          local wide = width >= 160
          local position = wide and "right" or "bottom"

          if term.opts.position ~= position then
            if term.win == current_win then
              focused_term = term
            end

            term:hide()
            term.opts.position = position
            term.opts.width = wide and 75 or 0
            term.opts.height = wide and 0 or 15
            term:show()
          end
        end
      end

      if focused_term and focused_term:win_valid() then
        vim.api.nvim_set_current_win(focused_term.win)
      elseif vim.api.nvim_win_is_valid(current_win) then
        vim.api.nvim_set_current_win(current_win)
      end
    end)
  end,
})

-- Responsive Terminal Placement on New Window
local moving_terminal = false
vim.api.nvim_create_autocmd("WinNew", {
  group = vim.api.nvim_create_augroup("TerminalFollowNewSplit", { clear = true }),
  callback = function()
    if moving_terminal then
      return
    end

    local new_win = vim.api.nvim_get_current_win()
    vim.schedule(function()
      if not vim.api.nvim_win_is_valid(new_win) then
        return
      end

      local buf = vim.api.nvim_win_get_buf(new_win)
      if
        vim.bo[buf].buftype ~= ""
        or vim.api.nvim_win_get_config(new_win).relative ~= ""
        or vim.api.nvim_get_current_win() ~= new_win
      then
        return
      end

      for _, term in ipairs(Snacks.terminal.list()) do
        if
          term:win_valid()
          and term.opts.relative == "win"
          and term.opts.win ~= new_win
          and vim.api.nvim_win_get_tabpage(term.win) == vim.api.nvim_win_get_tabpage(new_win)
          and (term.opts.position == "right" or term.opts.position == "bottom")
        then
          moving_terminal = true
          term:hide()

          local wide = vim.api.nvim_win_get_width(new_win) >= 160
          term.opts.win = new_win
          term.opts.position = wide and "right" or "bottom"
          term.opts.width = wide and 75 or 0
          term.opts.height = wide and 0 or 15

          term:show()

          vim.api.nvim_set_current_win(new_win)
          moving_terminal = false
          break
        end
      end
    end)
  end,
})

-- Allow dd to delete hovered entry from quick-fix
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "dd", function()
      local qf_list = vim.fn.getqflist()
      local current_line = vim.fn.line(".")
      table.remove(qf_list, current_line)
      vim.fn.setqflist(qf_list, "r")
    end, { buffer = true, silent = true })
  end,
})
