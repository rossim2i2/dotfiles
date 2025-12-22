local M = {}

local function starts_with(s, prefix)
  return s:sub(1, #prefix) == prefix
end

function M.in_zet_repo()
  local root = vim.g.zet_root or ""
  if root == "" then return false end
  local p = vim.fn.expand("%:p")
  -- normalize trailing slash
  if root:sub(-1) ~= "/" then root = root .. "/" end
  return starts_with(p, root)
end

function M.ensure_in_zet()
  if M.in_zet_repo() then return true end
  vim.notify("AI disabled outside zet repo", vim.log.levels.WARN)
  return false
end

return M

