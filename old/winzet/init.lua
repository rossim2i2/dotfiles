vim.api.nvim_create_user_command("ZetInbox", function(opts)
  local title = opts.args
  if title == "" then title = "untitled" end
  vim.cmd('silent !pwsh -NoProfile -File C:\\ZetScripts\\zet-new.ps1 -Type inbox -Title "'..title..'"')
end, { nargs="*" })

vim.api.nvim_create_user_command("ZetMeeting", function(opts)
  local title = opts.args
  if title == "" then title = "untitled" end
  vim.cmd('silent !pwsh -NoProfile -File C:\\ZetScripts\\zet-new.ps1 -Type meeting -Title "'..title..'" -OpenInNvim')
end, { nargs="*" })

local function zet_prompt(prompt)
  local t = vim.fn.input(prompt)
  if t == nil or t == "" then
    return "untitled"
  end
  return t
end

local function zet_create(note_type, title)
  local cmd = {
    "pwsh", "-NoProfile", "-File", "C:\\ZetScripts\\zet-new.ps1",
    "-Type", note_type,
    "-Title", title,
  }
  local out = vim.fn.systemlist(cmd)
  return out[#out] or ""
end

local function zet_new_and_open(note_type)
  local title = zet_prompt(note_type .. " title: ")
  local raw_path = zet_create(note_type, title)
  if raw_path == "" then
    vim.notify("Zet: failed to create " .. note_type, vim.log.levels.ERROR)
    return
  end

  -- Expand ~ just in case (shouldn't be needed if Resolve-Path is in zet-new.ps1)
  local path = vim.fn.expand(raw_path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

local function zet_inbox_capture_only()
  local title = zet_prompt("inbox title: ")
  local raw_path = zet_create("inbox", title)
  if raw_path == "" then
    vim.notify("Zet: failed to create inbox item", vim.log.levels.ERROR)
    return
  end

  -- Do NOT open the file. Just confirm.
  vim.notify("Zet inbox captured", vim.log.levels.INFO)
end

-- Keymaps
vim.keymap.set("n", "<leader>zi", zet_inbox_capture_only, { desc = "Zet: inbox capture (no open)" })
vim.keymap.set("n", "<leader>zn", function() zet_new_and_open("note") end,    { desc = "Zet: new note" })
vim.keymap.set("n", "<leader>zm", function() zet_new_and_open("meeting") end, { desc = "Zet: new meeting" })
vim.keymap.set("n", "<leader>zs", function() zet_new_and_open("sync") end,    { desc = "Zet: new sync" })
vim.keymap.set("n", "<leader>zp", function() zet_new_and_open("project") end, { desc = "Zet: new project" })


local function zet_process(to_type)
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("Zet: buffer has no file path", vim.log.levels.ERROR)
    return
  end
  local title = zet_prompt("new title (blank keeps current YAML title): ")
  local cmd = {
    "pwsh", "-NoProfile", "-File", "C:\\ZetScripts\\zet-process.ps1",
    "-Path", path,
    "-To", to_type,
  }
  if title ~= "" and title ~= "untitled" then
    table.insert(cmd, "-Title")
    table.insert(cmd, title)
  end
  local out = vim.fn.systemlist(cmd)
  local newpath = out[#out] or ""
  if newpath == "" then
    vim.notify("Zet: process failed", vim.log.levels.ERROR)
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(newpath))
end

vim.keymap.set("n", "<leader>zpa", function() zet_process("archive") end, { desc = "Zet: archive current" })
vim.keymap.set("n", "<leader>zpm", function() zet_process("meeting") end, { desc = "Zet: process -> meeting" })
vim.keymap.set("n", "<leader>zpp", function() zet_process("project") end, { desc = "Zet: process -> project" })
vim.keymap.set("n", "<leader>zps", function() zet_process("sync") end,    { desc = "Zet: process -> sync" })
vim.keymap.set("n", "<leader>zpn", function() zet_process("note") end,    { desc = "Zet: process -> note" })
-- Zet (no plugins): inbox picker + process shortcut
-- Requires: C:\ZetScripts\zet-new.ps1 and C:\ZetScripts\zet-process.ps1
-- Optional but recommended: zet-new.ps1 outputs Resolve-Path absolute path.

local function zet_systemlist(args)
  local out = vim.fn.systemlist(args)
  return out
end

local function zet_get_root()
  -- Pull $ZetRoot from C:\ZetScripts\zet.config.ps1
  local cmd = {
    "pwsh", "-NoProfile", "-Command",
    ". 'C:\\ZetScripts\\zet.config.ps1'; $ZetRoot"
  }
  local out = zet_systemlist(cmd)
  local root = (out[#out] or ""):gsub("\r", "")
  if root == "" then
    vim.notify("Zet: failed to read ZetRoot from zet.config.ps1", vim.log.levels.ERROR)
  end
  return root
end

local function zet_path_join(a, b)
  if a:sub(-1) == "\\" then return a .. b end
  return a .. "\\" .. b
end

local function zet_basename(p)
  return (p:gsub("\\+$", "")):match("([^\\]+)$") or p
end

local function zet_read_title_from_yaml(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines then return "" end
  -- look only in first ~60 lines to avoid loading huge files
  local max = math.min(#lines, 60)
  for i = 1, max do
    local line = lines[i]
    local t = line:match('^title:%s*"(.*)"%s*$')
    if t then return t end
  end
  return ""
end

local function zet_list_inbox_files()
  local root = zet_get_root()
  if root == "" then return {} end

  local inbox = zet_path_join(root, "Inbox")

  -- Use PowerShell to list files (fast, reliable on Windows, handles spaces).
  -- Output: full paths, newest first.
  local cmd = {
    "pwsh", "-NoProfile", "-Command",
    string.format("Get-ChildItem -LiteralPath '%s' -File -Filter *.md | Sort-Object LastWriteTime -Descending | ForEach-Object { $_.FullName }", inbox:gsub("'", "''"))
  }

  local out = zet_systemlist(cmd)
  local files = {}
  for _, p in ipairs(out) do
    p = (p or ""):gsub("\r", "")
    if p ~= "" then table.insert(files, p) end
  end
  return files
end

local function zet_inbox_picker()
  local files = zet_list_inbox_files()
  if #files == 0 then
    vim.notify("Zet: Inbox is empty (or Inbox folder missing)", vim.log.levels.INFO)
    return
  end

  -- Build display entries
  local items = {}
  for _, p in ipairs(files) do
    local base = zet_basename(p)
    -- nicer label: "yyyyMMddHHmmss - slug" (no .md)
    local label = base:gsub("%.md$", "")
    -- show YAML title if present (optional)
    local yaml_title = zet_read_title_from_yaml(p)
    if yaml_title ~= "" then
      label = label .. "  —  " .. yaml_title
    end
    table.insert(items, { label = label, path = p })
  end

  vim.ui.select(items, {
    prompt = "Zet Inbox (select to open):",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end
    vim.cmd("edit " .. vim.fn.fnameescape(choice.path))
  end)
end

local function zet_prompt(prompt, default)
  local t = vim.fn.input({ prompt = prompt, default = default or "" })
  if t == nil then return "" end
  return t
end

local function zet_find_path(lines)
  local candidates = {}
  for _, line in ipairs(lines) do
    line = (line or ""):gsub("\r", "")
    local p = line:match("^[A-Za-z]:\\.+%.md$")
    if p then table.insert(candidates, p) end
  end
  -- prefer an existing file
  for _, p in ipairs(candidates) do
    if vim.fn.filereadable(p) == 1 then return p end
  end
  return candidates[1] or ""
end

local function zet_read_title_from_yaml(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines then return "" end
  local max = math.min(#lines, 60)
  for i = 1, max do
    local t = lines[i]:match('^title:%s*"(.*)"%s*$')
    if t then return t end
  end
  return ""
end

local function zet_prompt(prompt, default)
  return vim.fn.input({ prompt = prompt, default = default or "" }) or ""
end

local function zet_process_current()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("Zet: current buffer has no file path", vim.log.levels.ERROR)
    return
  end

  local choices = {
    { label = "archive", to = "archive" },
    { label = "note",    to = "note" },
    { label = "meeting", to = "meeting" },
    { label = "project", to = "project" },
    { label = "sync",    to = "sync" },
  }

  vim.ui.select(choices, {
    prompt = "Process inbox item →",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end

    local current_title = zet_read_title_from_yaml(path)
    local new_title = zet_prompt("New title (blank keeps current): ", current_title)
    if new_title == "" then new_title = current_title end

    local cmd = {
      "pwsh","-NoProfile","-ExecutionPolicy","Bypass",
      "-File","C:\\ZetScripts\\zet-process.ps1",
      "-Path", path,
      "-To", choice.to,
    }
    if new_title ~= "" then
      table.insert(cmd, "-Title")
      table.insert(cmd, new_title)
    end

    local out = vim.fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify("Zet: process failed:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
      return
    end

    local newpath = zet_find_path(out)
    if newpath == "" then
      vim.notify("Zet: couldn't parse returned path:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
      return
    end

    newpath = vim.fn.fnamemodify(newpath, ":p")

    if vim.fn.filereadable(newpath) ~= 1 then
      vim.notify("Zet: processed file not found:\n" .. newpath, vim.log.levels.ERROR)
      return
    end

    -- Open the moved file (safe API form—avoids ex parsing issues)
    vim.cmd({ cmd = "edit", args = { newpath } })

    -- Close old buffer after switching
    local oldbuf = vim.fn.bufnr(path)
    if oldbuf ~= -1 and oldbuf ~= vim.api.nvim_get_current_buf() then
      pcall(vim.api.nvim_buf_delete, oldbuf, { force = true })
    end
  end)
end

-- Commands
vim.api.nvim_create_user_command("ZetInbox", zet_inbox_picker, {})
vim.api.nvim_create_user_command("ZetProcess", zet_process_current, {})

-- Keymaps (customize as you like)
-- Telescope-like inbox picker:
vim.keymap.set("n", "<leader>zf", zet_inbox_picker, { desc = "Zet: Inbox picker" })

-- Process current inbox item:
vim.keymap.set("n", "<leader>zp", zet_process_current, { desc = "Zet: Process current note" })

local function zet_archive_current()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("Zet: current buffer has no file path", vim.log.levels.ERROR)
    return
  end

  local out = vim.fn.systemlist({
    "pwsh","-NoProfile","-ExecutionPolicy","Bypass",
    "-File","C:\\ZetScripts\\zet-archive.ps1",
    "-Path", path
  })

  if vim.v.shell_error ~= 0 then
    vim.notify("Zet: archive failed:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end

  -- Find the returned path (should be exactly one line)
  local newpath = (out[#out] or ""):gsub("\r", "")
  if newpath == "" then
    vim.notify("Zet: archive returned empty path", vim.log.levels.ERROR)
    return
  end

  vim.cmd({ cmd = "edit", args = { newpath } })

  -- Close old buffer if still around
  local oldbuf = vim.fn.bufnr(path)
  if oldbuf ~= -1 and oldbuf ~= vim.api.nvim_get_current_buf() then
    pcall(vim.api.nvim_buf_delete, oldbuf, { force = true })
  end
end

vim.keymap.set("n", "<leader>za", zet_archive_current, { desc = "Zet: archive current note" })

