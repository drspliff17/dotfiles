local wk = require("which-key")
wk.add({
  { "<leader>h", group = "Harpoon", icon = { icon = "󱡅", color = "yellow" } },
})

local harpoon = require("harpoon")

return {
  "ThePrimeagen/harpoon",
  keys = {
    { "<leader>1", false },
    { "<leader>2", false },
    { "<leader>3", false },
    { "<leader>4", false },
    { "<leader>5", false },
    { "<leader>6", false },
    { "<leader>7", false },
    { "<leader>8", false },
    { "<leader>9", false },
    { "<leader>h", false },
    { "<leader>H", false },

    -- Reimplemented Keybindings
    {
      "<leader>ha",
      function()
        harpoon:list():add()
      end,
      desc = "Harpoon File",
    },
    {
      "<leader>hh",
      function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = "Harpoon Menu",
    },
    {
      "<leader>hn",
      function()
        harpoon:list():next()
      end,
      desc = "Goto Next",
    },
    {
      "<leader>hb",
      function()
        harpoon:list():prev()
      end,
      desc = "Goto Prev",
    },
    {
      "<leader>h1",
      function()
        harpoon:list():select(1)
      end,
      desc = "Goto File 1",
    },
    {
      "<leader>h2",
      function()
        harpoon:list():select(2)
      end,
      desc = "Goto File 2",
    },
    {
      "<leader>h3",
      function()
        harpoon:list():select(3)
      end,
      desc = "Goto File 3",
    },
    {
      "<leader>h4",
      function()
        harpoon:list():select(4)
      end,
      desc = "Goto File 4",
    },
    {
      "<leader>h5",
      function()
        harpoon:list():select(5)
      end,
      desc = "Goto File 5",
    },
    {
      "<leader>h6",
      function()
        harpoon:list():select(6)
      end,
      desc = "Goto File 6",
    },
    {
      "<leader>h7",
      function()
        harpoon:list():select(7)
      end,
      desc = "Goto File 7",
    },
    {
      "<leader>h8",
      function()
        harpoon:list():select(8)
      end,
      desc = "Goto File 8",
    },
    {
      "<leader>h9",
      function()
        harpoon:list():select(9)
      end,
      desc = "Goto File 9",
    },
  },
}
