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
    },
  },
}
