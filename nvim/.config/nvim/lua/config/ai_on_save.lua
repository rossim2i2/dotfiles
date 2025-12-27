local M = {}

local zet_root = "/home/rossim2i2/Repos/github.com/rossim2i2/zet"

local function is_in_zet(path)
	return path:sub(1, #zet_root) == zet_root
end

local function rel_from_root(abs)
	if abs:sub(1, #zet_root + 1) == zet_root .. "/" then
		return abs:sub(#zet_root + 2)
	end
	return abs
end

local function file_is_bad_name(rel)
	local base = rel:lower():match("([^/]+)$") or rel:lower()
	if base == "readme.md" then
		return true
	end
	if base:find("untitled", 1, true) then
		return true
	end
	if base:match("^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%.md$") then
		return true
	end -- 14-digit timestamp only
	return false
end

local function title_is_untitled()
	local lines = vim.api.nvim_buf_get_lines(0, 0, math.min(40, vim.api.nvim_buf_line_count(0)), false)
	local in_fm = false
	for _, line in ipairs(lines) do
		if line == "---" then
			in_fm = not in_fm
		elseif in_fm then
			local t = line:match("^%s*title:%s*(.+)%s*$")
			if t then
				t = t:gsub("^[\"']", ""):gsub("[\"']$", ""):lower()
				if t == "untitled" or t == "todo" or t == "tbd" or t == "" then
					return true
				end
				return false
			end
		end
	end
	return false
end

function M.setup()
	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = "*.md",
		callback = function(args)
			local abs = vim.api.nvim_buf_get_name(args.buf)
			if abs == "" or not is_in_zet(abs) then
				return
			end
			if abs:find("/.zk/", 1, true) or abs:find("/.git/", 1, true) then
				return
			end

			local rel = rel_from_root(abs)

			-- Only run when needed (prevents constant calls)
			if not (file_is_bad_name(rel) or title_is_untitled()) then
				return
			end

			local cmd = {
				"bash",
				"-lc",
				"cd "
					.. vim.fn.shellescape(zet_root)
					.. " && go run ./scripts/ai_frontmatter.go --on-create "
					.. vim.fn.shellescape(rel),
			}

			local out = vim.fn.systemlist(cmd)
			if vim.v.shell_error ~= 0 then
				return
			end

			-- Tool prints the final rel path; use the last non-empty line
			local final_rel = nil
			for i = #out, 1, -1 do
				local s = (out[i] or ""):gsub("%s+$", "")
				if s ~= "" then
					final_rel = s
					break
				end
			end
			if not final_rel then
				return
			end

			local final_abs = zet_root .. "/" .. final_rel
			if final_abs ~= abs then
				-- Switch buffer to renamed file
				vim.cmd("edit " .. vim.fn.fnameescape(final_abs))
				-- Close old buffer
				pcall(vim.cmd, "bwipeout " .. args.buf)
			end
		end,
	})
end

return M
