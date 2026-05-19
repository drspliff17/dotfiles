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

vim.keymap.set("n", "<leader>sL", "<cmd>LspInfo<CR>", { desc = "Open vim.lsp" })

vim.keymap.set("n", "<leader>o", "<cmd>Oil<CR>", { desc = "Open Oil (CWD)" })
vim.keymap.set("n", "<leader>O", "<cmd>Oil /home/drspliff<CR>", { desc = "Open Oil (~)" })
vim.keymap.set("n", "-", function()
  require("oil").toggle_float()
end)
