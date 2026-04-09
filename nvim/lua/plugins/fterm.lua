local state = {
   floating = {
      buf = -1,
      win = -1,
   },
}

local function create_floating_window(opts)
   opts = opts or {}

   local size = opts.sizePercentage or 0.8
   local width = math.floor(vim.o.columns * size)
   local height = math.floor(vim.o.lines * size)

   local row = math.floor((vim.o.lines - height) / 2)
   local col = math.floor((vim.o.columns - width) / 2)

   local buf = opts.buf
   if not vim.api.nvim_buf_is_valid(buf) then
      buf = vim.api.nvim_create_buf(false, true)
   end

   local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
   })

   vim.api.nvim_set_option_value("winhighlight", "Normal:Normal,NormalFloat:Normal,FloatBorder:Normal", { win = win })

   return { buf = buf, win = win }
end

local function setup_terminal_keymaps(buf)
   local opts = { buffer = buf }

   vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)

   vim.keymap.set("t", "<C-t>", function()
      vim.cmd("stopinsert")
      vim.api.nvim_win_hide(state.floating.win)
   end, opts)
end

local function toggle_fterm(cmd)
   if vim.api.nvim_win_is_valid(state.floating.win) then
      vim.api.nvim_win_hide(state.floating.win)
      return
   end

   state.floating = create_floating_window({
      buf = state.floating.buf,
   })

   if vim.bo[state.floating.buf].buftype ~= "terminal" then
      if cmd then
         vim.cmd("terminal " .. cmd)
      else
         vim.cmd("terminal")
      end

      setup_terminal_keymaps(state.floating.buf)

      vim.api.nvim_create_autocmd("TermClose", {
         buffer = state.floating.buf,
         once = true,
         callback = function()
            local buf = state.floating.buf

            if vim.api.nvim_win_is_valid(state.floating.win) then
               vim.api.nvim_win_close(state.floating.win, true)
            end

            if vim.api.nvim_buf_is_valid(buf) then
               vim.api.nvim_buf_delete(buf, { force = true })
            end

            state.floating.buf = -1
            state.floating.win = -1
         end,
      })
   end

   vim.cmd("startinsert")
end

vim.keymap.set({ "n", "t" }, "<C-t>", function()
   toggle_fterm()
end)

vim.api.nvim_create_user_command("Fterm", function(opts)
   toggle_fterm(opts.args ~= "" and opts.args or nil)
end, { nargs = "?" })

vim.api.nvim_set_hl(0, "NormalFloat", {
   link = "Normal",
})

vim.api.nvim_set_hl(0, "FloatBorder", {
   link = "Normal",
})

return {}
