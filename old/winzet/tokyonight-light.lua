-- tokyo night inspired minimal colorscheme (no plugin)
-- relies on terminal colors for base fg/bg

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

vim.o.termguicolors = true
vim.g.colors_name = "tokyonight-lite"

-- helper
local hi = function(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Core UI
hi("Normal",        { fg = "#c0caf5", bg = "NONE" })
hi("NormalNC",      { fg = "#a9b1d6", bg = "NONE" })
hi("CursorLine",    { bg = "#292e42" })
hi("CursorLineNr",  { fg = "#7aa2f7", bold = true })
hi("LineNr",        { fg = "#565f89" })
hi("SignColumn",    { bg = "NONE" })
hi("VertSplit",     { fg = "#414868" })
hi("StatusLine",    { fg = "#c0caf5", bg = "#1f2335" })
hi("StatusLineNC",  { fg = "#565f89", bg = "#1f2335" })

-- Selection
hi("Visual",        { bg = "#33467c" })

-- Popup / floating
hi("Pmenu",         { fg = "#c0caf5", bg = "#1f2335" })
hi("PmenuSel",      { fg = "#1f2335", bg = "#7aa2f7" })
hi("FloatBorder",   { fg = "#7aa2f7" })

-- Search
hi("Search",        { fg = "#1f2335", bg = "#e0af68" })
hi("IncSearch",     { fg = "#1f2335", bg = "#ff9e64" })

-- Diagnostics (even without LSP, used by messages)
hi("ErrorMsg",      { fg = "#f7768e", bold = true })
hi("WarningMsg",    { fg = "#e0af68" })

-- Markdown / prose friendly
hi("Title",         { fg = "#7aa2f7", bold = true })
hi("Underlined",    { fg = "#7dcfff", underline = true })
hi("Bold",          { bold = true })
hi("Italic",        { italic = true })

-- Syntax basics (works even without treesitter/LSP)
hi("Comment",       { fg = "#565f89", italic = true })
hi("String",        { fg = "#9ece6a" })
hi("Constant",      { fg = "#ff9e64" })
hi("Identifier",    { fg = "#c0caf5" })
hi("Statement",     { fg = "#bb9af7" })
hi("PreProc",       { fg = "#7dcfff" })
hi("Type",          { fg = "#2ac3de" })
hi("Special",       { fg = "#e0af68" })
