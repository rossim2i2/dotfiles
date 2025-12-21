return {
	"zk-org/zk-nvim",
	dependencies = {
		"nvim-telescope/telescope.nvim",
	},

	config = function()
		require("zk").setup({
			picker = "telescope",
			lsp = {
				config = {
					name = "zk",
					cmd = { "zk", "lsp" },
					filetypes = { "markdown" },
				},
				auto_attach = {
					enabled = true,
				},
			},
		})

		local zk_cmd = require("zk.commands")
		local zet_path = vim.fn.expand("~/Repos/github.com/rossim2i2/zet")

		-- Returns true if `file` is inside `root` (both resolved)
		local function is_in_dir(file, root)
			file = vim.fn.fnamemodify(vim.fn.resolve(file), ":p")
			root = vim.fn.fnamemodify(vim.fn.resolve(root), ":p")
			return file:sub(1, #root) == root
		end

		-- Run a git command in the zet repo
		local function git(args)
			return vim.system(vim.list_extend({ "git", "-C", zet_path }, args), { text = true })
		end

		-- Debounced push so you don’t push 50 times while editing
		local push_timer = vim.uv.new_timer()
		local function schedule_push()
			push_timer:stop()
			push_timer:start(1500, 0, function()
				vim.schedule(function()
					-- Push quietly; if it fails (offline/auth), we just notify.
					git({ "push" }):wait()
				end)
			end)
		end

		-- Commit + push current note (only if there are changes)
		local function commit_and_push(bufnr)
			local file = vim.api.nvim_buf_get_name(bufnr)
			if file == "" or not is_in_dir(file, zet_path) then
				return
			end

			-- Only act on markdown notes
			if vim.bo[bufnr].filetype ~= "markdown" then
				return
			end

			-- If nothing changed, do nothing
			local status = git({ "status", "--porcelain" }):wait()
			if status.code ~= 0 then
				vim.notify("zk git status failed:\n" .. (status.stderr or ""), vim.log.levels.WARN)
				return
			end
			if (status.stdout or ""):match("^%s*$") then
				return
			end

			-- Stage changes
			local add = git({ "add", "--", "." }):wait()
			if add.code ~= 0 then
				vim.notify("zk git add failed:\n" .. (add.stderr or ""), vim.log.levels.WARN)
				return
			end

			-- Commit with a nice message
			local msg = ("zk: %s"):format(vim.fn.fnamemodify(file, ":t"))
			local commit = git({ "commit", "-m", msg }):wait()

			-- If commit fails because there’s nothing to commit, ignore
			if commit.code ~= 0 then
				local err = (commit.stderr or "") .. (commit.stdout or "")
				if not err:match("nothing to commit") then
					vim.notify("zk git commit failed:\n" .. err, vim.log.levels.WARN)
				end
				return
			end

			-- Push (debounced)
			schedule_push()
		end

		-- Autocmd: on save, commit+push if this file is inside zet repo
		vim.api.nvim_create_augroup("ZkAutoGit", { clear = true })
		vim.api.nvim_create_autocmd("BufWritePost", {
			group = "ZkAutoGit",
			callback = function(args)
				commit_and_push(args.buf)
			end,
		})

		local function map(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, {
				noremap = true,
				silent = true,
				desc = desc,
			})
		end

		-- New note (always in ~/zet)
		map("<leader>zn", function()
			zk_cmd.get("ZkNew")({ notebook_path = zet_path })
		end, "Zk: New note")

		-- Open notes (Telescope, always uses ~/zet)
		map("<leader>zo", function()
			zk_cmd.get("ZkNotes")({
				sort = { "modified" },
				notebook_path = zet_path,
			})
		end, "Zk: Open note")

		-- Grep notes
		map("<leader>zg", function()
			zk_cmd.get("ZkGrep")({
				notebook_path = zet_path,
			})
		end, "Zk: Grep notes")

		-- Browse tags
		map("<leader>zt", function()
			zk_cmd.get("ZkTags")({
				notebook_path = zet_path,
			})
		end, "Zk: Tags")
	end,
}
