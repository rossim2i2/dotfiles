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

local function zet_new(note_type)
  local title = zet_prompt(note_type .. " title: ")
  -- Call pwsh to create, capture the returned file path
  local cmd = {
    "pwsh", "-NoProfile", "-File", "C:\\ZetScripts\\zet-new.ps1",
    "-Type", note_type,
    "-Title", title
  }
  local out = vim.fn.systemlist(cmd)
  local path = out[#out] or ""
  if path == "" then
    vim.notify("Zet: failed to create note", vim.log.levels.ERROR)
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

-- Shortcuts (pick your leader; examples assume <leader>z...)
vim.keymap.set("n", "<leader>zi", function() zet_new("inbox") end,  { desc = "Zet: new inbox" })
vim.keymap.set("n", "<leader>zn", function() zet_new("note") end,   { desc = "Zet: new note" })
vim.keymap.set("n", "<leader>zm", function() zet_new("meeting") end, { desc = "Zet: new meeting" })
vim.keymap.set("n", "<leader>zs", function() zet_new("sync") end,   { desc = "Zet: new sync" })

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
