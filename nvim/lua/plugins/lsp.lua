return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      gdscript = {
        capabilities = capabilities,
        settings = {},
        cmd = vim.fn.has("win32") == 1 and { "ncat", "localhost", os.getenv("GDScript_Port") or "6005" } or nil,
      },

      bashls = {
        capabilities = capabilities,
        settings = {},
      },

      lua_ls = {
        capabilities = capabilities,
        settings = {
          Lua = {
            workspace = {
              library = {
                -- vim.fn.expand("~/.local/share/hyprland-meta/hl.meta.lua"),
                vim.fn.expand("/usr/share/hypr/stubs/hl.meta.lua"),
              },
              checkThirdParty = false,
            },
          },
        },
      },
      qmlls = {
        cmd = { "qmlls", "-E" },
        filetypes = { "qml", "qmljs" },
        settings = {
          qmlls = {
            importPaths = {
              "/usr/lib/qt6/qml",
            },
          },
        },
      },
    },
  },
}
