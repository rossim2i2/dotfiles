local M = {}

local function zet_root()
	return "/home/rossim2i2/Repos/github.com/rossim2i2/zet"
end

local function is_inbox_file(path)
	local root = zet_root()
	return path:sub(1, #root + 7) == (root .. "/inbox/")
end

local function is_git_repo()
	local root = zet_root()
	local out = vim.fn.system({ "git", "-C", root, "rev-parse", "--is-inside-work-tree" })
	return out:match("true") ~= nil
end

local function is_tracked(relpath)
	local root = zet_root()
	-- exit code 0 if tracked
	vim.fn.system({ "git", "-C", root, "ls-files", "--error-unmatch", relpath })
	return vim.v.shell_error == 0
end

local function rel_from_root(abs)
	local root = zet_root()
	return abs:gsub("^" .. vim.pesc(root) .. "/?", "")
end

local function ensure_dir(dir)
	vim.fn.mkdir(dir, "p")
end

local function git_mv(src_rel, dst_rel)
	local root = zet_root()
	vim.fn.system({ "git", "-C", root, "mv", src_rel, dst_rel })
	return vim.v.shell_error == 0
end

local function git_rm(rel)
	local root = zet_root()
	vim.fn.system({ "git", "-C", root, "rm", rel })
	return vim.v.shell_error == 0
end

local function fs_mv(src_abs, dst_abs)
	ensure_dir(vim.fn.fnamemodify(dst_abs, ":h"))
	vim.fn.system({ "mv", src_abs, dst_abs })
	return vim.v.shell_error == 0
end

local function fs_rm(abs)
	vim.fn.system({ "rm", "-f", abs })
	return vim.v.shell_error == 0
end

local function close_current_buffer()
	vim.cmd("bwipeout!")
end

local function update_type_in_buffer(new_type)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local in_fm = false

	for i, line in ipairs(lines) do
		if line == "---" then
			in_fm = not in_fm
		elseif in_fm and line:match("^type:%s*") then
			lines[i] = "type: " .. new_type
			vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
			vim.cmd("write")
			return true
		end
	end

	return false
end

function M.process_current_inbox()
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		vim.notify("No file path for current buffer", vim.log.levels.WARN)
		return
	end
	if not is_inbox_file(file) then
		vim.notify("Not an inbox file: " .. file, vim.log.levels.WARN)
		return
	end

	local root = zet_root()
	local rel = rel_from_root(file)
	local use_git = is_git_repo()
	local tracked = use_git and is_tracked(rel)

	local actions = {
		{ label = "Convert to note (move out of inbox)", value = "convert" },
		{ label = "Mark done (archive)", value = "done" },
		{ label = "Delete", value = "delete" },
		{ label = "Cancel", value = "cancel" },
	}

	vim.ui.select(actions, {
		prompt = "Inbox action",
		format_item = function(item)
			return item.label
		end,
	}, function(choice)
		if not choice or choice.value == "cancel" then
			return
		end

		if choice.value == "done" then
			local dst_abs = root .. "/archive/inbox/" .. vim.fn.fnamemodify(file, ":t")
			local dst_rel = rel_from_root(dst_abs)
			local ok = false

			if tracked then
				ensure_dir(root .. "/archive/inbox")
				ok = git_mv(rel, dst_rel)
			else
				ok = fs_mv(file, dst_abs)
			end

			if ok then
				vim.notify("Archived: " .. dst_rel)
				close_current_buffer()
			else
				vim.notify("Archive failed", vim.log.levels.ERROR)
			end
			return
		end

		if choice.value == "delete" then
			local ok = false
			if tracked then
				ok = git_rm(rel)
			else
				ok = fs_rm(file)
			end
			if ok then
				vim.notify("Deleted: " .. rel)
				close_current_buffer()
			else
				vim.notify("Delete failed", vim.log.levels.ERROR)
			end
			return
		end

		if choice.value == "convert" then
			-- Update frontmatter: inbox -> note
			update_type_in_buffer("note")

			-- Move to repo root (or change to root .. "/notes/" if you want a notes dir)
			local dst_abs = root .. "/" .. vim.fn.fnamemodify(file, ":t")
			local dst_rel = rel_from_root(dst_abs)

			local ok = false
			if tracked then
				ok = git_mv(rel, dst_rel)
			else
				ok = fs_mv(file, dst_abs)
			end

			if not ok then
				vim.notify("Move failed", vim.log.levels.ERROR)
				return
			end

			-- Optional: run your Go tool to set tags/title/rename if needed
			-- (This is the best place to do it “at processing time” instead of always at capture)
			-- local cmd = {
			-- 	"bash",
			-- 	"-lc",
			-- 	"cd "
			-- 		.. shellescape(root)
			-- 		.. " && go run ./scripts/ai_frontmatter.go --staged=false --apply=true "
			-- 		.. shellescape(dst_rel),
			-- }
			-- vim.fn.system(cmd)

			vim.notify("Converted to note: " .. dst_rel)

			-- Open the converted note
			vim.cmd("edit " .. vim.fn.fnameescape(dst_abs))

			-- Close the old inbox buffer (now hidden)
			vim.cmd("bwipeout #")
		end
	end)
end

return M
