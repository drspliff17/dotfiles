local wk = require("which-key")
wk.add({
  { "<leader>sg", group = "FZF Grep", icon = { icon = "󰍉", color = "yellow" } },
  { "<leader>sc", group = "FZF CMD/History", icon = { icon = "󰍉", color = "yellow" } },
  { "<leader>ss", group = "FZF Search", icon = { icon = "󰍉", color = "yellow" } },
  { "<leader>se", group = "FZF Extras", icon = { icon = "󰍉", color = "yellow" } },
})

return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-mini/mini.icons" },
  lazy = true,
  config = function()
    require("fzf-lua").setup({
      "fzf-native",

      fzf_opts = {
        ["--no-scrollbar"] = false,
        ["--cycle"] = true,
        ["--ansi"] = true,
        ["--height"] = "100%",
        ["--highlight-line"] = true,
      },

      winopts = {
        preview = {
          layout = "horizontal",
          horizontal = "down:40%",
        },
      },

      defaults = {
        formatter = "path.dirname_first",
      },

      keymap = {
        fzf = {
          ["ctrl-j"] = "down",
          ["ctrl-k"] = "up",
          ["ctrl-b"] = "preview-page-up",
          ["ctrl-f"] = "preview-page-down",
          ["ctrl-u"] = "half-page-up",
          ["ctrl-d"] = "half-page-down",
          ["ctrl-c"] = "abort",
          ["ctrl-q"] = "abort",
        },
      },
    })
  end,

  keys = {

    { "<leader>:", false },
    { "<leader>/", false },
    { "<leader>,", false },
    { "<leader>fn", false },
    { "<leader>ft", false },
    { "<leader>fT", false },
    { "<leader>sG", false },
    { "<leader>sC", false },
    { "<leader>sM", false },
    { "<leader>s/", false },
    { "<leader>sw", false },
    { "<leader>sW", false },
    { "<leader>sa", false },
    { "<leader>sd", false },
    { "<leader>sD", false },
    { "<leader>sH", false },
    { "<leader>sR", false },
    { "<leader>sj", false },
    { "<leader>sl", false },
    { "<leader>sq", false },
    { "<leader>sS", false },
    { '<leader>s"', false },

    -- Reused Defaults
    {
      "<leader><leader>",
      function()
        require("fzf-lua").files({
          "ivy",
          winopts = {
            title = " 󰞦 Files 󰞦 ",
            width = 0.75,
            height = 0.85,
            col = 0.5,
            border = "rounded",
            preview = {
              layout = "horizontal",
              horizontal = "up:65%",
            },
          },
        })
      end,
      desc = "Find files (Root Dir)",
    },
    {
      "<leader>sb",
      function()
        require("fzf-lua").buffers({
          "ivy",
          winopts = {
            title = " 󰞦 Buffers 󰞦 ",
            height = 0.30,
            border = "rounded",
            preview = {
              layout = "vertical",
              vertical = "right:65%",
            },
          },
        })
      end,
      desc = "Search Buffers",
    },
    {
      "<leader>sh",
      function()
        require("fzf-lua").help_tags({
          "ivy",
          winopts = {
            title = " 󰞦 Help 󰞦 ",
            height = 0.75,
            width = 0.70,
            col = 0.5,
            border = "rounded",
          },
        })
      end,
      desc = "Search Help Tags",
    },
    {
      "<leader>sr",
      function()
        require("fzf-lua").resume()
      end,
      desc = "Resume FZF",
    },
    {
      "<leader>sm",
      function()
        require("fzf-lua").marks({
          "ivy",
          winopts = {
            title = " 󰞦 Marks 󰞦 ",
            width = 0.7,
            height = 0.6,
            col = 0.5,
            border = "rounded",
            preview = {
              border = "double",
              scrollbar = false,
            },
          },
        })
      end,
      desc = "Search Marks",
    },
    {
      "<leader>sk",
      function()
        require("fzf-lua").keymaps({
          winopts = {
            title = " 󰞦 Keymaps 󰞦 ",
            width = 0.7,
            preview = {
              layout = "horizontal",
              horizontal = "up:30%",
            },
          },
        })
      end,
      desc = "Search Keymaps",
    },

    -- Custom Grouping, Grep
    {
      "<leader>sgc",
      function()
        require("fzf-lua").lgrep_curbuf({
          "ivy",
          winopts = {
            title = " 󰞦 Live Grep 󰞦 ",
            border = "rounded",
            width = 0.75,
            height = 0.70,
            col = 0.5,
            preview = {
              layout = "horizontal",
              horizontal = "up:75%",
            },
          },
        })

        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-g>", true, false, true), "n", false)
      end,
      desc = "Live Grep (Cur Buf)",
    },
    {
      "<leader>sgg",
      function()
        require("fzf-lua").grep({
          "ivy",
          winopts = {
            title = " 󰞦 Grep 󰞦 ",
            border = "rounded",
            width = 0.75,
            height = 0.70,
            col = 0.5,
            preview = {
              layout = "horizontal",
              horizontal = "up:75%",
            },
          },
        })
      end,
      desc = "Grep (CWD)",
    },
    {
      "<leader>sgl",
      function()
        require("fzf-lua").live_grep({
          "ivy",
          winopts = {
            title = " 󰞦 Live Grep 󰞦 ",
            border = "rounded",
            width = 0.75,
            height = 0.70,
            col = 0.5,
            preview = {
              layout = "horizontal",
              horizontal = "up:75%",
            },
          },
        })
      end,
      desc = "Live Grep (CWD)",
    },
    {
      "<leader>sgw",
      function()
        require("fzf-lua").grep_cword({
          "ivy",
          winopts = {
            title = " 󰞦 Grep 󰞦 ",
            border = "rounded",
            width = 0.75,
            height = 0.70,
            col = 0.5,
            preview = {
              layout = "horizontal",
              horizontal = "up:75%",
            },
          },
        })
      end,
      desc = "Grep Word (CWD)",
    },

    -- Custom Grouping, Commdand / History
    {
      "<leader>scc",
      function()
        require("fzf-lua").commands({
          "ivy",
          winopts = {
            title = " 󰞦 Commands 󰞦 ",
            border = "rounded",
            width = 0.70,
            height = 0.80,
            col = 0.5,
            preview = {
              layout = "horizontal",
              horizontal = "up:40%",
            },
          },
        })
      end,
      desc = "Search Commands",
    },
    {
      "<leader>sch",
      function()
        require("fzf-lua").command_history({
          winopts = {
            title = " 󰞦 Command History 󰞦 ",
            width = 0.65,
            height = 0.70,
          },
        })
      end,
      desc = "Search CMD History",
    },
    {
      "<leader>sc/",
      function()
        require("fzf-lua").search_history({
          winopts = {
            title = " 󰞦 Search History 󰞦 ",
            width = 0.65,
            height = 0.70,
          },
        })
      end,
      desc = "Search History",
    },

    -- Custom Grouping, Search Extended
    {
      "<leader>ssa",
      function()
        require("fzf-lua").autocmds({
          winopts = {
            title = " 󰞦 Search Autocommands 󰞦 ",
            width = 0.65,
            height = 0.70,
            preview = {
              layout = "horizontal",
              horizontal = "up:40%",
            },
          },
        })
      end,
      desc = "Search Autocommands",
    },
    {
      "<leader>ssc",
      function()
        require("fzf-lua").files({
          "ivy",
          cwd = vim.fn.stdpath("config"),
          winopts = {
            title = " 󰞦 Config 󰞦 ",
            width = 0.75,
            height = 0.85,
            col = 0.5,
            border = "rounded",
            preview = {
              layout = "horizontal",
              horizontal = "up:65%",
            },
          },
        })
      end,
      desc = "Search Config Dir",
    },
    {
      "<leader>ssh",
      function()
        require("fzf-lua").highlights({
          winopts = {
            title = " 󰞦 Highlights 󰞦 ",
            preview = {
              layout = "horizontal",
              horizontal = "up:20%",
            },
          },
        })
      end,
      desc = "Search Highlights",
    },
    {
      "<leader>ssj",
      function()
        require("fzf-lua").jumps({
          winopts = {
            title = " 󰞦 Jumplist 󰞦 ",
            preview = {
              layout = "horizontal",
              horizontal = "up:30%",
            },
          },
        })
      end,
      desc = "Search Jumplist",
    },
    {
      "<leader>ssl",
      function()
        require("fzf-lua").loclist({
          winopts = {
            title = " 󰞦 Location List 󰞦 ",
            preview = {
              layout = "horizontal",
              horizontal = "up:30%",
            },
          },
        })
      end,
      desc = "Search Locations",
    },
    {
      "<leader>ssr",
      function()
        require("fzf-lua").registers({
          "ivy",
          winopts = {
            title = " 󰞦 Registers 󰞦 ",
            border = "rounded",
            width = 0.75,
            height = 0.8,
            col = 0.5,
            preview = {
              layout = "horizontal",
              horizontal = "up:20%",
              border = "double",
            },
          },
        })
      end,
      desc = "Search Registers",
    },

    -- Custom Grouping, Extra Stuff
    {
      "<leader>sed",
      function()
        require("fzf-lua").diagnostics_document({
          winopts = {
            title = " 󰞦 Document Diagnostics 󰞦 ",
            preview = {
              layout = "horizontal",
              horizontal = "up:40%",
            },
          },
        })
      end,
      desc = "Document Diagnostics",
    },
    {
      "<leader>seD",
      function()
        require("fzf-lua").diagnostics_workspace({
          winopts = {
            title = " 󰞦 Workspace Diagnostics 󰞦 ",
            preview = {
              layout = "horizontal",
              horizontal = "up:40%",
            },
          },
        })
      end,
      desc = "Workspace Diagnostics",
    },
    {
      "<leader>seq",
      function()
        require("fzf-lua").quickfix({
          winopts = {
            title = " 󰞦 Quickfix List 󰞦 ",
          },
        })
      end,
      desc = "Quickfix List",
    },
    {
      "<leader>ses",
      function()
        require("fzf-lua").lsp_document_symbols({
          winopts = {
            title = " 󰞦 Document Symbols 󰞦 ",
            preview = {
              layout = "horizontal",
              horizontal = "up:30%",
            },
          },
        })
      end,
      desc = "LSP Doc Symbols",
    },
    {
      "<leader>seS",
      function()
        require("fzf-lua").lsp_workspace_symbols({
          winopts = {
            title = " 󰞦 Workspace Symbols 󰞦 ",
            preview = {
              layout = "horizontal",
              horizontal = "up:30%",
            },
          },
        })
      end,
      desc = "LSP Workspace Symbols",
    },
    {
      "<leader>seo",
      function()
        require("fzf-lua").nvim_options({
          winopts = {
            title = " 󰞦 Neovim Options 󰞦 ",
            preview = {
              layout = "horizontal",
              horizontal = "up:50%",
            },
          },
        })
      end,
      desc = "Nvim Options",
    },
  },
}
