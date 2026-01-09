------------------------------------------------------------
-- Leader
------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

------------------------------------------------------------
-- Theme
------------------------------------------------------------
vim.cmd.colorscheme("tokyonight-lite")
vim.api.nvim_set_hl(0, "@markup.heading", { fg = "#7aa2f7", bold = true })

------------------------------------------------------------
-- Basic Settings (kept from yours)
------------------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.scrolloff = 4
vim.opt.wrap = false

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

-- You said rg isn't installed. Don't force grepprg to rg.
-- vim.opt.grepprg = "rg --vimgrep"
-- vim.opt.grepformat = "%f:%l:%c:%m"

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "80"
vim.opt.showmatch = true
vim.opt.matchtime = 2

vim.opt.lazyredraw = false
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000
vim.opt.synmaxcol = 300

-- File handling
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 0
vim.opt.autoread = true
vim.opt.autowrite = false

vim.opt.errorbells = false
vim.opt.backspace = "indent,eol,start"
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"

vim.opt.splitbelow = true
vim.opt.splitright = true

-- Prefer pwsh if you want, but leaving this alone is usually fine.
-- vim.o.shell = "powershell.exe"

------------------------------------------------------------
-- Quality-of-life mappings (kept)
------------------------------------------------------------
vim.keymap.set("n", "<leader>bn", "<Cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

vim.keymap.set("n", "<leader>sv", "<Cmd>vsplit<CR>", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sh", "<Cmd>split<CR>", { desc = "Split window horizontally" })

vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

local highlight_yank_group = vim.api.nvim_create_augroup("HighlightYank", {})
vim.api.nvim_create_autocmd("TextYankPost", {
  group = highlight_yank_group,
  pattern = "*",
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

------------------------------------------------------------
-- Windows-safe temp dirs (keep this; ensure it is ONLY ONCE)
------------------------------------------------------------
if vim.fn.has("win32") == 1 then
  local base = vim.fn.stdpath("state")
  local function ensure(p)
    if vim.fn.isdirectory(p) == 0 then vim.fn.mkdir(p, "p") end
  end

  local swap = base .. "\\swap"
  local undo = base .. "\\undo"
  local backup = base .. "\\backup"
  local view = base .. "\\view"

  ensure(swap); ensure(undo); ensure(backup); ensure(view)

  vim.opt.directory = { swap .. "\\\\", "." }
  vim.opt.undodir = { undo }
  vim.opt.backupdir = { backup }
  vim.opt.viewdir = view

  vim.opt.undofile = true
  vim.opt.backup = true
  vim.opt.writebackup = true
end

------------------------------------------------------------
-- Zet core (single implementation)
------------------------------------------------------------
local Zet = {}

Zet.scripts = {
  new = "C:\\ZetScripts\\zet-new.ps1",
  process = "C:\\ZetScripts\\zet-process.ps1",
  archive = "C:\\ZetScripts\\zet-archive.ps1",
  config = "C:\\ZetScripts\\zet.config.ps1",
}

local function ps_systemlist(cmd)
  local out = vim.fn.systemlist(cmd)
  return out
end

local function parse_windows_md_path(lines)
  for _, line in ipairs(lines) do
    line = (line or ""):gsub("\r", "")
    local p = line:match("^[A-Za-z]:\\.+%.md$")
    if p then return p end
  end
  return ""
end

local function prompt_title(prompt)
  local t = vim.fn.input(prompt)
  if t == nil or t == "" then return "untitled" end
  return t
end

local function wait_for_file(path)
  return vim.wait(2000, function()
    return vim.fn.filereadable(path) == 1 and vim.fn.getfsize(path) > 0
  end, 50)
end

-- Cache ZetRoot once per session (faster)
Zet._root = nil
function Zet.root()
  if Zet._root and Zet._root ~= "" then return Zet._root end
  local out = ps_systemlist({
    "pwsh", "-NoProfile", "-Command",
    ". '" .. Zet.scripts.config .. "'; $ZetRoot"
  })
  Zet._root = (out[#out] or ""):gsub("\r", "")
  if Zet._root == "" then
    vim.notify("Zet: failed to read ZetRoot from zet.config.ps1", vim.log.levels.ERROR)
  end
  return Zet._root
end

local function zet_new(note_type, title)
  local out = ps_systemlist({
    "pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", Zet.scripts.new,
    "-Type", note_type,
    "-Title", title,
  })
  if vim.v.shell_error ~= 0 then return nil, out end
  local p = parse_windows_md_path(out)
  if p == "" then return nil, out end
  return vim.fn.fnamemodify(p, ":p"), out
end

local function zet_new_and_open(note_type)
  local title = prompt_title(note_type .. " title: ")
  local path, out = zet_new(note_type, title)
  if not path then
    vim.notify("Zet: create failed:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end
  if not wait_for_file(path) then
    vim.notify("Zet: file not ready:\n" .. path, vim.log.levels.ERROR)
    return
  end
  vim.cmd({ cmd = "edit", args = { path } })
  vim.cmd("edit!") -- force disk reload so template shows
end

local function zet_inbox_capture()
  local title = prompt_title("inbox title: ")
  local path, out = zet_new("inbox", title)
  if not path then
    vim.notify("Zet: inbox capture failed:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end
  vim.notify("Zet: inbox captured", vim.log.levels.INFO)
end

local function zet_archive_current()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    vim.notify("Zet: current buffer has no file path", vim.log.levels.ERROR)
    return
  end

  local out = ps_systemlist({
    "pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", Zet.scripts.archive,
    "-Path", path,
  })

  if vim.v.shell_error ~= 0 then
    vim.notify("Zet: archive failed:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_buf_delete(buf, { force = true })
  vim.notify("Zet: archived", vim.log.levels.INFO)
end

local function zet_process_menu()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("Zet: current buffer has no file path", vim.log.levels.ERROR)
    return
  end

  local choices = {
    { label = "note",    to = "note" },
    { label = "meeting", to = "meeting" },
    { label = "project", to = "project" },
    { label = "sync",    to = "sync" },
  }

  vim.ui.select(choices, {
    prompt = "Process →",
    format_item = function(i) return i.label end,
  }, function(choice)
    if not choice then return end

    local new_title = vim.fn.input("New title (blank = keep): ")
    local cmd = {
      "pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass",
      "-File", Zet.scripts.process,
      "-Path", path,
      "-To", choice.to,
    }
    if new_title and new_title ~= "" then
      table.insert(cmd, "-Title")
      table.insert(cmd, new_title)
    end

    local out = ps_systemlist(cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify("Zet: process failed:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
      return
    end

    local newpath = parse_windows_md_path(out)
    if newpath == "" then
      vim.notify("Zet: process returned no path:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
      return
    end

    newpath = vim.fn.fnamemodify(newpath, ":p")
    vim.cmd({ cmd = "edit", args = { newpath } })
  end)
end

------------------------------------------------------------
-- Finder / picker loop (one implementation)
------------------------------------------------------------
local function zet_collect(kind, find, limit)
  local root = Zet.root()
  if root == "" then return {} end

  local folders = {
    inbox = "Inbox",
    meetings = "Meetings",
    notes = "Notes",
    projects = "Projects",
    syncs = "Syncs",
    archive = "Archive",
  }

  local kinds = {}
  if kind == "recent" then
    kinds = { "inbox", "meetings", "notes", "projects", "syncs", "archive" }
  else
    kinds = { kind }
  end

  local items = {}

  for _, k in ipairs(kinds) do
    local dir = root .. "\\" .. folders[k]
    local ps = string.format([[
      $dir = '%s'
      if (Test-Path -LiteralPath $dir) {
        Get-ChildItem -LiteralPath $dir -File -Filter *.md |
          Sort-Object LastWriteTime -Descending |
          Select-Object -First %d |
          ForEach-Object { $_.FullName }
      }
    ]], dir:gsub("'", "''"), limit)

    local out = ps_systemlist({ "pwsh", "-NoProfile", "-Command", ps })
    for _, p in ipairs(out) do
      p = (p or ""):gsub("\r", "")
      if p ~= "" then
        local name = p:match("([^\\]+)$") or p
        if find == "" or name:lower():find(find:lower(), 1, true) then
          table.insert(items, { kind = k, path = p, name = name })
        end
      end
    end
  end

  return items
end

local function zet_picker_loop(kind)
  local limit = 75
  local find = ""

  while true do
    local items = zet_collect(kind, find, limit)

    vim.cmd("redraw")
    vim.api.nvim_echo({{("Zet %s  |  limit=%d  |  filter=%s"):format(kind, limit, (find ~= "" and find or "(none)")), "Title"}}, false, {})
    vim.api.nvim_echo({{"------------------------------------------------------------", "Comment"}}, false, {})

    if #items == 0 then
      vim.api.nvim_echo({{"No matches.", "WarningMsg"}}, false, {})
    else
      for i = 1, math.min(#items, limit) do
        local it = items[i]
        vim.api.nvim_echo({{("%3d) [%s] %s"):format(i, it.kind, it.name)}}, false, {})
      end
    end

    vim.api.nvim_echo({{""}}, false, {})
    vim.api.nvim_echo({{"Commands: number=open | /text=set filter | /=clear | r=refresh | q=quit", "Comment"}}, false, {})

    local inp = vim.fn.input("Select: ")
    if inp == nil or inp == "" or inp == "q" then
      vim.cmd("redraw")
      return
    end

    if inp == "r" then
      -- refresh
    elseif inp:sub(1,1) == "/" then
      find = inp:sub(2)
    elseif inp:match("^%d+$") then
      local idx = tonumber(inp)
      if idx >= 1 and idx <= #items then
        local path = vim.fn.fnamemodify(items[idx].path, ":p")
        vim.cmd({ cmd = "edit", args = { path } })
        return
      else
        vim.api.nvim_echo({{"Out of range. Press Enter...", "WarningMsg"}}, false, {})
        vim.fn.input("")
      end
    else
      vim.api.nvim_echo({{"Invalid input. Press Enter...", "WarningMsg"}}, false, {})
      vim.fn.input("")
    end
  end
end

------------------------------------------------------------
-- Keymaps: <leader>z = captures/actions, <leader>f = finds
------------------------------------------------------------
-- Captures / actions
vim.keymap.set("n", "<leader>zi", zet_inbox_capture, { desc = "Zet: inbox capture (no open)" })
vim.keymap.set("n", "<leader>zm", function() zet_new_and_open("meeting") end, { desc = "Zet: new meeting" })
vim.keymap.set("n", "<leader>zn", function() zet_new_and_open("note") end,    { desc = "Zet: new note" })
vim.keymap.set("n", "<leader>zs", function() zet_new_and_open("sync") end,    { desc = "Zet: new sync" })
vim.keymap.set("n", "<leader>zp", function() zet_new_and_open("project") end, { desc = "Zet: new project" })

vim.keymap.set("n", "<leader>za", zet_archive_current, { desc = "Zet: archive current (close)" })
vim.keymap.set("n", "<leader>zx", zet_process_menu,    { desc = "Zet: process current (menu)" })

-- Finds / pickers
vim.keymap.set("n", "<leader>fi", function() zet_picker_loop("inbox") end,    { desc = "Find: inbox" })
vim.keymap.set("n", "<leader>fm", function() zet_picker_loop("meetings") end, { desc = "Find: meetings" })
vim.keymap.set("n", "<leader>fn", function() zet_picker_loop("notes") end,    { desc = "Find: notes" })
vim.keymap.set("n", "<leader>fp", function() zet_picker_loop("projects") end, { desc = "Find: projects" })
vim.keymap.set("n", "<leader>fs", function() zet_picker_loop("syncs") end,    { desc = "Find: syncs" })
vim.keymap.set("n", "<leader>fr", function() zet_picker_loop("recent") end,   { desc = "Find: recent (all)" })
