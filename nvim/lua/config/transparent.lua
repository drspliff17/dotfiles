local ignore_patterns = {
  "^Visual",
  "^Search",
  "^IncSearch",
  "^Substitute",
  "^MatchParen",
  "^Diff",
  "^Diagnostic",
  "^Spell",
  "^PmenuSel",
  "^WildMenu",
  "^CursorLine",
  "^ColorColumn",
  "^@",
}

local force_prefixes = {
  "^Snacks",
  "^NeoTree",
  "^FzfLua",
  "^MiniFiles",
  "^LazyButton",
  "^WhichKey",
}

local function matches_any(name, patterns)
  for _, pat in ipairs(patterns) do
    if name:match(pat) then
      return true
    end
  end
  return false
end

local function smart_transparency()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  local normal_bg = normal.bg

  for _, name in ipairs(vim.fn.getcompletion("", "highlight")) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name })
    if ok and hl.bg ~= nil then
      if matches_any(name, force_prefixes) then
        vim.api.nvim_set_hl(0, name, { bg = "none" })
      elseif hl.bg == normal_bg and not matches_any(name, ignore_patterns) then
        vim.api.nvim_set_hl(0, name, { bg = "none", ctermbg = "none" })
      end
    end
  end

  vim.cmd("highlight! SnacksDashboardDesc guibg=NONE")
  vim.cmd("highlight! FzfLuaNormal guibg=NONE")
  vim.cmd("highlight! FzfLuaBackdrop guibg=NONE")
end
smart_transparency()

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = smart_transparency,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "SnacksDashboardOpened",
  callback = function()
    smart_transparency()
  end,
})
