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
