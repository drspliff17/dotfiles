return {
  "smoka7/hop.nvim",
  version = "*",
  opts = {
    keys = "asdfghjklmnbvcxzertyuio",
    quit_key = "q",
  },
  keys = {
    { "sp", "<cmd>HopPatternMW<cr>", desc = "Hop Pattern MW", mode = "n", noremap = true },
    { "ss", "<cmd>HopChar1MW<cr>", desc = "Hop Char MW", mode = "n", noremap = true },
    { "sw", "<cmd>HopWordMW<cr>", desc = "Hop Word MW", mode = "n", noremap = true },
    { "sl", "<cmd>HopLineMW<cr>", desc = "Hop Line MW", mode = "n", noremap = true },
    { "sa", "<cmd>HopAnywhereMW<cr>", desc = "Hop Anywehere MW", mode = "n", noremap = true },
    { "sls", "<cmd>HopLineStartMW<cr>", desc = "Hop Line Start MW", mode = "n", noremap = true },
  },
}
