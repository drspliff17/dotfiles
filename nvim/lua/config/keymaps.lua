-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

-- Open Last Yank v3
-- If last yank is an absolute path, that exists, it will open it.
-- Else, it will try the base dir of the active buffer, as a relative path.
-- Finally, it will try the relative path of nvim's current working dir for a
-- match with the contents of register 0
local function OpenLastYank()
  local p = vim.trim(vim.fn.getreg("0"))
  if p == "" then
    return
  end

  local function exists(path)
    return vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
  end

  local function open(path)
    vim.cmd.edit(vim.fn.fnameescape(path))
  end

  if p:sub(1, 1) == "~" or p:sub(1, 1) == "$" then
    p = vim.fs.normalize(p)
  end

  if vim.fn.isabsolutepath(p) == 1 then
    if exists(p) then
      open(p)
      return
    end
    vim.notify("Path does not exist: " .. p, vim.log.levels.ERROR, { title = "Open Last Yank" })
    return
  end

  local buffer_name = vim.api.nvim_buf_get_name(0)
  local buffer_dir = buffer_name ~= "" and vim.fs.dirname(buffer_name) or nil
  if buffer_dir then
    local buffer_path = vim.fs.normalize(vim.fs.joinpath(buffer_dir, p))
    if exists(buffer_path) then
      open(buffer_path)
      return
    end
  end

  local cwd_path = vim.fs.normalize(vim.fs.joinpath(vim.fn.getcwd(), p))
  if exists(cwd_path) then
    open(cwd_path)
    return
  end

  vim.notify("Path does not exist: " .. p, vim.log.levels.ERROR, { title = "Open Last Yank" })
end

vim.keymap.set("n", "s", "<Nop>")

vim.keymap.set("i", "jj", "<Esc>", { noremap = true, silent = true, nowait = true })
vim.keymap.set("i", "JJ", "<Esc>", { noremap = true, silent = true, nowait = true })
vim.keymap.set("i", "fj", "<Esc>", { noremap = true, silent = true, nowait = true })
vim.keymap.set("i", "FJ", "<Esc>", { noremap = true, silent = true, nowait = true })
vim.keymap.set("i", "jf", "<Esc>", { noremap = true, silent = true, nowait = true })
vim.keymap.set("i", "JF", "<Esc>", { noremap = true, silent = true, nowait = true })

vim.keymap.set("n", "<leader>D", function()
  Snacks.dashboard()
end, { desc = "Open Snacks Dashboard" })

vim.keymap.set("n", "<leader>xs", "<cmd>source %<CR>", { desc = "Source Current File" })

-- Quick-Yank stuff
vim.keymap.set("n", "<leader>po", OpenLastYank, { desc = "Open last yanked path" })

vim.keymap.set("n", "<leader>pw", function()
  vim.cmd.normal({ "yiW", bang = true })
  OpenLastYank()
end, { desc = "yiW, then OpenLastYank" })

vim.keymap.set("n", "<leader>pq", function()
  vim.cmd.normal({ "yiq" })
  OpenLastYank()
end, { desc = "yiq, then OpenLastYank" })

-- Lsp
vim.keymap.set("n", "<leader>sL", "<cmd>LspInfo<CR>", { desc = "Open vim.lsp" })
vim.keymap.set("n", "<leader>so", "<cmd>lsp restart<CR>", { desc = "Run lsp restart" })

-- Oil
vim.keymap.set("n", "<leader>o", "<cmd>Oil<CR>", { desc = "Open Oil (CWD)" })
vim.keymap.set("n", "<leader>O", "<cmd>Oil /home/drspliff<CR>", { desc = "Open Oil (~)" })
vim.keymap.set("n", "-", function()
  require("oil").toggle_float()
end)

-- toggle.nvim
vim.keymap.set({ "n", "v" }, "<leader>t", require("toggle").toggle, {
  desc = "Toggle word under cursor",
})

-- Bufferline
vim.keymap.set("n", "<A-h>", "<cmd>BufferLineMovePrev<CR>", { desc = "Move Buffer Left" })
vim.keymap.set("n", "<A-l>", "<cmd>BufferLineMoveNext<CR>", { desc = "Move Buffer Right" })

-- Terminal mode
vim.keymap.set("t", "<C-q>", [[<C-\><C-n>]], { noremap = true })

-- Opening Terminal Buffers
vim.keymap.set({ "n", "t" }, "<c-/>", function()
  Snacks.terminal(nil, { cwd = vim.fn.getcwd() })
  vim.cmd("wincmd L")
  vim.cmd("vertical resize 75")
end, { desc = "Terminal (CWD)" })

vim.keymap.set("n", "<leader>ft", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
  vim.cmd("wincmd L")
  vim.cmd("vertical resize 75")
end, { desc = "Terminal (Root)" })

vim.keymap.set("n", "<leader>fT", function()
  Snacks.terminal(nil, { cwd = vim.env.HOME })
  vim.cmd("wincmd L")
  vim.cmd("vertical resize 75")
end, { desc = "Terminal (Home)" })

-- Command mode cancel
vim.keymap.set("c", "<C-q>", "<C-c>", {
  noremap = true,
  silent = true,
})
