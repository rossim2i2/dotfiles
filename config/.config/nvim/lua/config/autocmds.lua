-- ============================================================================
-- TITLE : auto-commands
-- ABOUT : automatically run code on defined events (e.g. save, yank)
-- ============================================================================
-- local on_attach = require("utils.lsp").on_attach

-- Restore last cursor position when reopening a file
local last_cursor_group = vim.api.nvim_create_augroup("LastCursorGroup", {})
vim.api.nvim_create_autocmd("BufReadPost", {
	group = last_cursor_group,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Highlight the yanked text for 200ms
local highlight_yank_group = vim.api.nvim_create_augroup("HighlightYank", {})
vim.api.nvim_create_autocmd("TextYankPost", {
	group = highlight_yank_group,
	pattern = "*",
	callback = function()
		vim.hl.on_yank({
			higroup = "IncSearch",
			timeout = 200,
		})
	end,
})

-- format on save using efm langserver and configured formatters
local lsp_fmt_group = vim.api.nvim_create_augroup("FormatOnSaveGroup", {})
vim.api.nvim_create_autocmd("BufWritePre", {
	group = lsp_fmt_group,
	callback = function(args)
		local efm = vim.lsp.get_clients({ name = "efm" })
		local filename = vim.api.nvim_buf_get_name(args.buf)
		if vim.tbl_isempty(efm) then
			return
		end
		--paterns to exclude
		local disable_patterns = {
			"defualt.md",
		}
		for _, pattern in ipairs(disable_patterns) do
			if filename:match(pattern) then
				return
			end
		end
		vim.lsp.buf.format({ name = "efm", async = true })
	end,
})

-- on attach function shortcuts
--local lsp_on_attach_group = vim.api.nvim_create_augroup("LspMappings", {})
--vim.api.nvim_create_autocmd("LspAttach", {
--	group = lsp_on_attach_group,
--	callback = on_attach,
--})

-- open terminal in insert mode
vim.api.nvim_create_autocmd("TermOpen", {
	group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
	callback = function()
		vim.opt.number = false
		vim.opt.relativenumber = false
		vim.cmd("startinsert")
	end,
})

vim.keymap.set("n", "<space>st", function()
	vim.cmd("botright 15split | terminal")
end)

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
		vim.opt_local.textwidth = 0
		vim.opt_local.colorcolumn = "80"
	end,
})
