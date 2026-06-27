-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

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

-- Task Script
vim.keymap.set("n", "<C-i>", function()
  local task = vim.fn.input("Task: ")
  local runMode = "-t"
  if task:match("^%d+$") then
    runMode = "-i"
  end
  vim.system({
    "task",
    "-t",
    vim.fn.getcwd(),
    "-r",
    runMode,
    task,
  })
end, { desc = "Run Task In CWD" })
