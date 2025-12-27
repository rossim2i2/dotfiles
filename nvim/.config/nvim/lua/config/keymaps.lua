-- ============================================================================
-- TITLE: NeoVim keymaps
-- ABOUT: sets some quality-of-life keymaps
-- ============================================================================

-- Buffer navigation
vim.keymap.set("n", "<leader>bn", "<Cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })

-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Splitting & Resizing
vim.keymap.set("n", "<leader>sv", "<Cmd>vsplit<CR>", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sh", "<Cmd>split<CR>", { desc = "Split window horizontally" })
vim.keymap.set("n", "<C-Up>", "<Cmd>resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", "<Cmd>resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", "<Cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", "<Cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Better indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Better J behavior
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

-- Quick config editing
vim.keymap.set("n", "<leader>rc", "<Cmd>e ~/.config/nvim/init.lua<CR>", { desc = "Edit config" })

-- Inline Execution
vim.keymap.set("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Execute File" })
vim.keymap.set("n", "<leader>x", ":.lua<CR>", { desc = "Execute Line" })
vim.keymap.set("v", "<leader>x", ":lua<CR>", { desc = "Execute Selection" })

-- Save / Quit
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })

-- Clear search highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Exit Terminal Mode
vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")

-- Oil NVIM File Tree
vim.keymap.set("n", "-", "<cmd>Oil<CR>")

-- Ollma binds
vim.keymap.set("n", "<leader>on", ":Ollama<CR>", { desc = "Ollama: new chat" })

vim.keymap.set("v", "<leader>os", function()
	require("ollama").prompt("Summarize and convert into atomic notes:")
end, { desc = "Ollama: summarize selection" })

vim.keymap.set("v", "<leader>or", function()
	require("ollama").prompt("Rewrite clearly and concisely:")
end, { desc = "Ollama: rewrite selection" })

-- Gen binds
local ai_guard = require("utils.ai_guard")

-- gen.nvim (visual transforms)
vim.keymap.set("v", "<leader>za", function()
	if not ai_guard.ensure_in_zet() then
		return
	end
	vim.cmd("Gen ZK_Atomic")
end, { desc = "ZK: atomic notes from selection" })

vim.keymap.set("v", "<leader>zt", function()
	if not ai_guard.ensure_in_zet() then
		return
	end
	vim.cmd("Gen ZK_TitleTags")
end, { desc = "ZK: title + tags from selection" })

vim.keymap.set("v", "<leader>zr", function()
	if not ai_guard.ensure_in_zet() then
		return
	end
	vim.cmd("Gen ZK_Rewrite")
end, { desc = "ZK: rewrite selection" })

-- optional: open Gen prompt picker
vim.keymap.set({ "n", "v" }, "<leader>zg", function()
	if not ai_guard.ensure_in_zet() then
		return
	end
	vim.cmd("Gen")
end, { desc = "ZK: Gen prompt picker" })

--Process Zet Inbox
vim.keymap.set("n", "<leader>ip", function()
	require("config.inbox").process_current_inbox()
end, { desc = "Process inbox item" })

-- native neovim keymaps
vim.keymap.set("n", "<leader>gd", "<cmd>Lspsaga peek_definition<CR>") -- goto definition
vim.keymap.set("n", "<leader>gD", "<cmd>Lspsaga goto_definition<CR>") -- goto definition
vim.keymap.set("n", "<leader>gS", "<cmd>vsplit | Lspsaga goto_definition<CR>") -- goto definition in split
vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>") -- Code actions
vim.keymap.set("n", "<leader>rn", "<cmd>Lspsaga rename<CR>") -- Rename symbol
vim.keymap.set("n", "<leader>D", "<cmd>Lspsaga show_line_diagnostics<CR>") -- Line diagnostics (float)
vim.keymap.set("n", "<leader>d", "<cmd>Lspsaga show_cursor_diagnostics<CR>") -- Cursor diagnostics
vim.keymap.set("n", "<leader>pd", "<cmd>Lspsaga diagnostic_jump_prev<CR>") -- previous diagnostic
vim.keymap.set("n", "<leader>nd", "<cmd>Lspsaga diagnostic_jump_next<CR>") -- next diagnostic
vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>") -- hover documentation

-- fzf-lua keymaps
vim.keymap.set("n", "<leader>fd", "<cmd>FzfLua lsp_finder<CR>") -- LSP Finder (definition + references)
vim.keymap.set("n", "<leader>fr", "<cmd>FzfLua lsp_references<CR>") -- Show all references to the symbol under the cursor
vim.keymap.set("n", "<leader>ft", "<cmd>FzfLua lsp_typedefs<CR>") -- Jump to the type definition of the symbol under the cursor
vim.keymap.set("n", "<leader>fs", "<cmd>FzfLua lsp_document_symbols<CR>") -- List all symbols (functions, classes, etc.) in the current file
vim.keymap.set("n", "<leader>fs", "<cmd>FzfLua lsp_workspace_symbols<CR>") -- Search for any symbol across the entire project/workspace
vim.keymap.set("n", "<leader>fi", "<cmd>FzfLua lsp_implementations<CR>") -- Go to implementation
