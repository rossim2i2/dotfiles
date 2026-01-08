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
