-- ============================================================
-- init.lua (plugin-free Zet workflow on Windows)
--  - <leader>z... = capture/actions
--  - <leader>f... = find/pickers (current tab + preview pane)
--  - <leader>fg   = fuzzy search (content-aware, no plugins)
--  - Action Items: [ ] @person ... (open)   [x] @person ... (done)
--
-- Requirements:
--   - PowerShell (pwsh) available
--   - C:\ZetScripts\zet.config.ps1 sets $ZetRoot
--   - C:\ZetScripts\zet-new.ps1 / zet-process.ps1 / zet-archive.ps1 exist
-- ============================================================

------------------------------------------------------------
-- Leader
------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

------------------------------------------------------------
-- Theme
------------------------------------------------------------
vim.opt.termguicolors = true
vim.cmd.colorscheme("tokyonight-lite")
vim.api.nvim_set_hl(0, "@markup.heading", { fg = "#7aa2f7", bold = true })

------------------------------------------------------------
-- Basic Settings
------------------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.scrolloff = 4
vim.opt.wrap = false

-- Tabbing / Indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Visual
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "80"
vim.opt.showmatch = true
vim.opt.matchtime = 2
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000
vim.opt.synmaxcol = 300

-- File Handling
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 0
vim.opt.autoread = true
vim.opt.autowrite = false

-- Behavior
vim.opt.errorbells = false
vim.opt.backspace = "indent,eol,start"
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

------------------------------------------------------------
-- Windows-safe temp dirs (swap/undo/backup/view)
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
-- Quality-of-life keymaps
------------------------------------------------------------
vim.keymap.set("n", "<leader>bn", "<Cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

vim.keymap.set("n", "<leader>sv", "<Cmd>vsplit<CR>", { desc = "Split vertical" })
vim.keymap.set("n", "<leader>sh", "<Cmd>split<CR>", { desc = "Split horizontal" })

vim.keymap.set("v", "<", "<gv", { desc = "Indent left + reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right + reselect" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines keep cursor" })

-- Clear search highlight (global)
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Yank highlight
local highlight_yank_group = vim.api.nvim_create_augroup("HighlightYank", {})
vim.api.nvim_create_autocmd("TextYankPost", {
  group = highlight_yank_group,
  pattern = "*",
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- ============================================================
-- Zet (PowerShell-backed, plugin-free)
-- ============================================================
local Zet = {
  scripts = {
    new = "C:\\ZetScripts\\zet-new.ps1",
    process = "C:\\ZetScripts\\zet-process.ps1",
    archive = "C:\\ZetScripts\\zet-archive.ps1",
    config = "C:\\ZetScripts\\zet.config.ps1",
  },
  _root = nil,
}

local function ps_systemlist(cmd)
  return vim.fn.systemlist(cmd)
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
  vim.cmd("edit!") -- show template reliably
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

-- ============================================================
-- Shared UI helpers (scratch buffers + preview split)
-- ============================================================

local function buf_scratch(name)
  local b = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(b, name)
  vim.bo[b].buftype = "nofile"
  vim.bo[b].bufhidden = "wipe"
  vim.bo[b].swapfile = false
  vim.bo[b].modifiable = true
  return b
end

local function set_buf_lines(b, lines)
  vim.bo[b].modifiable = true
  vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
  vim.bo[b].modifiable = false
end

local function basename(p)
  return (p:gsub("\\+$", "")):match("([^\\]+)$") or p
end

local function read_yaml_title(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines then return "" end
  local max = math.min(#lines, 60)
  for i = 1, max do
    local t = lines[i]:match('^title:%s*"(.*)"%s*$')
    if t then return t end
  end
  return ""
end

-- ============================================================
-- Picker: Files (preview), current tab
-- ============================================================

-- PowerShell list: outputs "kind|fullpath" sorted globally by LastWriteTimeUtc
local function ps_list(kind, limit)
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

  local specs = {}
  for _, k in ipairs(kinds) do
    local d = root .. "\\" .. folders[k]
    table.insert(specs, ("@{Kind='%s'; Dir='%s'}"):format(k, d:gsub("'", "''")))
  end

  local ps = ([[
    $specs = @(
      %s
    )
    $items = foreach ($s in $specs) {
      if (Test-Path -LiteralPath $s.Dir) {
        Get-ChildItem -LiteralPath $s.Dir -File -Filter *.md |
          ForEach-Object {
            [pscustomobject]@{
              Kind = $s.Kind
              Path = $_.FullName
              Time = $_.LastWriteTimeUtc
            }
          }
      }
    }
    $items |
      Sort-Object Time -Descending |
      Select-Object -First %d |
      ForEach-Object { "$($_.Kind)|$($_.Path)" }
  ]]):format(table.concat(specs, ",\n      "), limit)

  local out = vim.fn.systemlist({ "pwsh", "-NoProfile", "-Command", ps })
  local items = {}
  for _, line in ipairs(out) do
    line = (line or ""):gsub("\r", "")
    if line ~= "" then
      local k, p = line:match("^([^|]+)|(.+)$")
      if k and p then
        table.insert(items, { kind = k, path = p, name = basename(p) })
      end
    end
  end
  return items
end

local function open_picker(kind)
  local orig_win = vim.api.nvim_get_current_win()
  local orig_buf = vim.api.nvim_get_current_buf()
  local orig_view = vim.fn.winsaveview()

  local state = {
    kind = kind,
    limit = 120,
    find = "",
    items = {},
    idx = 1,

    orig_win = orig_win,
    orig_buf = orig_buf,
    orig_view = orig_view,

    list_win = orig_win,
    list_buf = nil,
    prev_win = nil,
    prev_buf = nil,
  }

  local function cleanup()
    if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
      pcall(vim.api.nvim_win_close, state.prev_win, true)
    end
    if vim.api.nvim_win_is_valid(state.orig_win) then
      pcall(vim.api.nvim_set_current_win, state.orig_win)
      if vim.api.nvim_buf_is_valid(state.orig_buf) then
        pcall(vim.api.nvim_win_set_buf, state.orig_win, state.orig_buf)
        pcall(vim.fn.winrestview, state.orig_view)
      end
    end
  end

  local function render_list()
    local header = {
      ("Zet Find: %s   limit=%d   filter=%s"):format(state.kind, state.limit, (state.find ~= "" and state.find or "(none)")),
      "------------------------------------------------------------",
      "j/k or arrows = move   Enter = open   / = filter   r = refresh   Esc/q = quit",
      "",
    }

    local lines = {}
    for _, h in ipairs(header) do table.insert(lines, h) end

    if #state.items == 0 then
      table.insert(lines, "No matches.")
    else
      for i, it in ipairs(state.items) do
        local marker = (i == state.idx) and ">" or " "
        table.insert(lines, ("%s %3d) [%-8s] %s"):format(marker, i, it.kind, it.name))
      end
    end

    set_buf_lines(state.list_buf, lines)
    local row = 4 + math.max(state.idx, 1)
    pcall(vim.api.nvim_win_set_cursor, state.list_win, { row, 0 })
  end

  local function render_preview()
    if not (state.prev_buf and vim.api.nvim_buf_is_valid(state.prev_buf)) then return end
    if #state.items == 0 then
      set_buf_lines(state.prev_buf, { "No preview." })
      return
    end

    local it = state.items[state.idx]
    if not it or it.path == "" then
      set_buf_lines(state.prev_buf, { "No preview." })
      return
    end

    local lines = { it.path, "------------------------------------------------------------" }
    local ok, file_lines = pcall(vim.fn.readfile, it.path)
    if not ok or not file_lines then
      table.insert(lines, "(Could not read file)")
      set_buf_lines(state.prev_buf, lines)
      return
    end

    local max = math.min(#file_lines, 120)
    for i = 1, max do table.insert(lines, file_lines[i]) end
    if #file_lines > max then table.insert(lines, "…") end
    set_buf_lines(state.prev_buf, lines)
  end

  local function refresh()
    local items = ps_list(state.kind, state.limit)

    if state.find ~= "" then
      local f = state.find:lower()
      local filtered = {}
      for _, it in ipairs(items) do
        if it.name:lower():find(f, 1, true) then table.insert(filtered, it) end
      end
      items = filtered
    end

    state.items = items
    state.idx = (#state.items == 0) and 1 or math.max(1, math.min(state.idx, #state.items))
    render_list()
    render_preview()
  end

  local function move(delta)
    if #state.items == 0 then return end
    state.idx = math.max(1, math.min(#state.items, state.idx + delta))
    render_list()
    render_preview()
  end

  local function open_selected()
    if #state.items == 0 then return end
    local it = state.items[state.idx]
    if not it or it.path == "" then return end

    local p = vim.fn.fnamemodify(it.path, ":p")

    if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
      pcall(vim.api.nvim_win_close, state.prev_win, true)
      state.prev_win = nil
    end

    vim.api.nvim_set_current_win(state.list_win)
    vim.cmd({ cmd = "edit", args = { p } })
  end

  local function quit()
    cleanup()
  end

  local ok, err = pcall(function()
    if vim.api.nvim_buf_get_name(0) == "" and vim.bo.buftype == "" then
      vim.cmd("enew")
    end

    state.list_buf = buf_scratch("ZetList")
    vim.api.nvim_win_set_buf(state.list_win, state.list_buf)

    vim.cmd("vsplit")
    state.prev_win = vim.api.nvim_get_current_win()
    state.prev_buf = buf_scratch("ZetPreview")
    vim.api.nvim_win_set_buf(state.prev_win, state.prev_buf)

    vim.cmd("wincmd h")
    state.list_win = vim.api.nvim_get_current_win()

    vim.wo[state.list_win].number = false
    vim.wo[state.list_win].relativenumber = false
    vim.wo[state.list_win].cursorline = true

    vim.wo[state.prev_win].number = false
    vim.wo[state.prev_win].relativenumber = false
    vim.wo[state.prev_win].wrap = false

    local mapopts = { buffer = state.list_buf, nowait = true, silent = true }

    vim.keymap.set("n", "j", function() move(1) end, mapopts)
    vim.keymap.set("n", "k", function() move(-1) end, mapopts)
    vim.keymap.set("n", "<Down>", function() move(1) end, mapopts)
    vim.keymap.set("n", "<Up>", function() move(-1) end, mapopts)

    vim.keymap.set("n", "<CR>", open_selected, mapopts)
    vim.keymap.set("n", "<Esc>", quit, mapopts)
    vim.keymap.set("n", "q", quit, mapopts)
    vim.keymap.set("n", "r", refresh, mapopts)

    vim.keymap.set("n", "/", function()
      local newf = vim.fn.input("Filter (blank clears): ", state.find)
      if newf == nil then return end
      state.find = newf
      state.idx = 1
      refresh()
    end, mapopts)

    refresh()
  end)

  if not ok then
    cleanup()
    vim.notify("Picker error: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- ============================================================
-- Picker: Action Items (open items + by @person), preview
-- ============================================================

local function ps_actions_list(mode, person, limit)
  local root = Zet.root()
  if root == "" then return {} end

  local folders = { "Inbox", "Meetings", "Notes", "Projects", "Syncs" }
  local quoted_dirs = {}
  for _, f in ipairs(folders) do
    local d = (root .. "\\" .. f):gsub("'", "''")
    table.insert(quoted_dirs, ("'%s'"):format(d))
  end

  local pat_open = [[\[\s\]\s*(?:@(?<person>[A-Za-z0-9._-]+))?\s*(?<text>.+)]]
  local pat_done = [[\[(?:x|X)\]\s*(?:@(?<person>[A-Za-z0-9._-]+))?\s*(?<text>.+)]]

  local pat = pat_open
  if mode == "done" then pat = pat_done end
  if mode == "all" then
    pat = [[\[(?:\s|x|X)\]\s*(?:@(?<person>[A-Za-z0-9._-]+))?\s*(?<text>.+)]]
  end

  local person_filter = ""
  if person and person ~= "" then
    person_filter = (" | Where-Object { $_.Line -match '@%s\\b' }"):format(person:gsub("'", "''"))
  end

  local ps = ([[
    $dirs = @(%s)
    $files = foreach ($d in $dirs) {
      if (Test-Path -LiteralPath $d) {
        Get-ChildItem -LiteralPath $d -Recurse -File -Filter *.md -ErrorAction SilentlyContinue
      }
    }
    if (-not $files) { return }
    $hits = $files | Select-String -Pattern '%s' -AllMatches
    $hits %s |
      Select-Object -First %d |
      ForEach-Object { "$($_.Path)|$($_.LineNumber)|$($_.Line)" }
  ]]):format(table.concat(quoted_dirs, ","), pat:gsub("'", "''"), person_filter, limit)

  local out = vim.fn.systemlist({ "pwsh", "-NoProfile", "-Command", ps })
  local items = {}
  for _, line in ipairs(out) do
    line = (line or ""):gsub("\r", "")
    if line ~= "" then
      local p, ln, txt = line:match("^(.-)|(%d+)|(.+)$")
      if p and ln and txt then
        table.insert(items, { path = p, lnum = tonumber(ln), text = txt })
      end
    end
  end
  return items
end

local function open_actions_picker(opts)
  local orig_win = vim.api.nvim_get_current_win()
  local orig_buf = vim.api.nvim_get_current_buf()
  local orig_view = vim.fn.winsaveview()

  local state = {
    mode = opts.mode or "open",
    person = opts.person,
    limit = 300,
    find = "",
    items = {},
    idx = 1,

    orig_win = orig_win,
    orig_buf = orig_buf,
    orig_view = orig_view,

    list_win = orig_win,
    list_buf = nil,
    prev_win = nil,
    prev_buf = nil,
  }

  local function cleanup()
    if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
      pcall(vim.api.nvim_win_close, state.prev_win, true)
    end
    if vim.api.nvim_win_is_valid(state.orig_win) then
      pcall(vim.api.nvim_set_current_win, state.orig_win)
      if vim.api.nvim_buf_is_valid(state.orig_buf) then
        pcall(vim.api.nvim_win_set_buf, state.orig_win, state.orig_buf)
        pcall(vim.fn.winrestview, state.orig_view)
      end
    end
  end

  local function render_list()
    local title = ("Action Items: %s%s  limit=%d  filter=%s"):format(
      state.mode,
      (state.person and state.person ~= "") and (" @" .. state.person) or "",
      state.limit,
      (state.find ~= "" and state.find or "(none)")
    )

    local header = {
      title,
      "------------------------------------------------------------",
      "j/k or arrows = move   Enter = open @ line   / = filter   r = refresh   Esc/q = quit",
      "",
    }

    local lines = {}
    for _, h in ipairs(header) do table.insert(lines, h) end

    if #state.items == 0 then
      table.insert(lines, "No matches.")
    else
      for i, it in ipairs(state.items) do
        local marker = (i == state.idx) and ">" or " "
        local short = it.text:gsub("%s+", " ")
        if #short > 120 then short = short:sub(1, 120) .. "…" end
        table.insert(lines, ("%s %3d) %s  [%s:%d]"):format(marker, i, short, basename(it.path), it.lnum))
      end
    end

    set_buf_lines(state.list_buf, lines)
    local row = 4 + math.max(state.idx, 1)
    pcall(vim.api.nvim_win_set_cursor, state.list_win, { row, 0 })
  end

  local function render_preview()
    if not (state.prev_buf and vim.api.nvim_buf_is_valid(state.prev_buf)) then return end
    if #state.items == 0 then
      set_buf_lines(state.prev_buf, { "No preview." })
      return
    end

    local it = state.items[state.idx]
    if not it or it.path == "" then
      set_buf_lines(state.prev_buf, { "No preview." })
      return
    end

    local ok, file_lines = pcall(vim.fn.readfile, it.path)
    if not ok or not file_lines then
      set_buf_lines(state.prev_buf, { it.path, "------------------------------------------------------------", "(Could not read file)" })
      return
    end

    local lnum = math.max(1, it.lnum or 1)
    local start = math.max(1, lnum - 6)
    local stop = math.min(#file_lines, lnum + 6)

    local lines = { it.path, ("Line %d"):format(lnum), "------------------------------------------------------------" }
    for i = start, stop do
      local prefix = (i == lnum) and ">>" or "  "
      local num = ("%4d"):format(i)
      table.insert(lines, ("%s %s  %s"):format(prefix, num, file_lines[i]))
    end

    set_buf_lines(state.prev_buf, lines)
  end

  local function refresh()
    local items = ps_actions_list(state.mode, state.person, state.limit)

    if state.find ~= "" then
      local f = state.find:lower()
      local filtered = {}
      for _, it in ipairs(items) do
        local hay = (it.text .. " " .. basename(it.path)):lower()
        if hay:find(f, 1, true) then table.insert(filtered, it) end
      end
      items = filtered
    end

    state.items = items
    state.idx = (#state.items == 0) and 1 or math.max(1, math.min(state.idx, #state.items))
    render_list()
    render_preview()
  end

  local function move(delta)
    if #state.items == 0 then return end
    state.idx = math.max(1, math.min(#state.items, state.idx + delta))
    render_list()
    render_preview()
  end

  local function open_selected()
    if #state.items == 0 then return end
    local it = state.items[state.idx]
    if not it or it.path == "" then return end

    local p = vim.fn.fnamemodify(it.path, ":p")
    local lnum = it.lnum or 1

    if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
      pcall(vim.api.nvim_win_close, state.prev_win, true)
      state.prev_win = nil
    end

    vim.api.nvim_set_current_win(state.list_win)
    vim.cmd({ cmd = "edit", args = { p } })
    pcall(vim.api.nvim_win_set_cursor, 0, { lnum, 0 })
    vim.cmd("normal! zz")
  end

  local function quit()
    cleanup()
  end

  local ok, err = pcall(function()
    if vim.api.nvim_buf_get_name(0) == "" and vim.bo.buftype == "" then
      vim.cmd("enew")
    end

    state.list_buf = buf_scratch("ZetActions")
    vim.api.nvim_win_set_buf(state.list_win, state.list_buf)

    vim.cmd("vsplit")
    state.prev_win = vim.api.nvim_get_current_win()
    state.prev_buf = buf_scratch("ZetActionPreview")
    vim.api.nvim_win_set_buf(state.prev_win, state.prev_buf)

    vim.cmd("wincmd h")
    state.list_win = vim.api.nvim_get_current_win()

    vim.wo[state.list_win].number = false
    vim.wo[state.list_win].relativenumber = false
    vim.wo[state.list_win].cursorline = true

    vim.wo[state.prev_win].number = false
    vim.wo[state.prev_win].relativenumber = false
    vim.wo[state.prev_win].wrap = false

    local mapopts = { buffer = state.list_buf, nowait = true, silent = true }

    vim.keymap.set("n", "j", function() move(1) end, mapopts)
    vim.keymap.set("n", "k", function() move(-1) end, mapopts)
    vim.keymap.set("n", "<Down>", function() move(1) end, mapopts)
    vim.keymap.set("n", "<Up>", function() move(-1) end, mapopts)

    vim.keymap.set("n", "<CR>", open_selected, mapopts)
    vim.keymap.set("n", "<Esc>", quit, mapopts)
    vim.keymap.set("n", "q", quit, mapopts)
    vim.keymap.set("n", "r", refresh, mapopts)

    vim.keymap.set("n", "/", function()
      local newf = vim.fn.input("Filter (blank clears): ", state.find)
      if newf == nil then return end
      state.find = newf
      state.idx = 1
      refresh()
    end, mapopts)

    refresh()
  end)

  if not ok then
    cleanup()
    vim.notify("Actions picker error: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- ============================================================
-- Picker: Fuzzy Search (content-aware), preview
--   - Scope: all folders EXCEPT Archive
--   - Query entered via "/" (like your other pickers)
--   - "Fuzzy": subsequence + token coverage scoring
--   - Results: top 25
--
-- Notes:
--   - To keep it fast without rg, we only scan a RECENT candidate pool
--     (default 500 newest files across Inbox/Meetings/Notes/Projects/Syncs).
--   - We fuzzy-score against: filename + YAML title + first ~400 lines of content.
--   - If you want “everything” (not just recent pool), we can, but it’ll be slower.
-- ============================================================

local function ps_recent_pool_no_archive(limit)
  local root = Zet.root()
  if root == "" then return {} end

  local folders = { "Inbox", "Meetings", "Notes", "Projects", "Syncs" }
  local specs = {}
  for _, f in ipairs(folders) do
    local d = (root .. "\\" .. f):gsub("'", "''")
    table.insert(specs, ("'%s'"):format(d))
  end

  local ps = ([[
    $dirs = @(%s)
    $items = foreach ($d in $dirs) {
      if (Test-Path -LiteralPath $d) {
        Get-ChildItem -LiteralPath $d -File -Filter *.md -Recurse -ErrorAction SilentlyContinue |
          ForEach-Object {
            [pscustomobject]@{ Path=$_.FullName; Time=$_.LastWriteTimeUtc }
          }
      }
    }
    $items |
      Sort-Object Time -Descending |
      Select-Object -First %d |
      ForEach-Object { $_.Path }
  ]]):format(table.concat(specs, ","), limit)

  local out = vim.fn.systemlist({ "pwsh", "-NoProfile", "-Command", ps })
  local paths = {}
  for _, p in ipairs(out) do
    p = (p or ""):gsub("\r", "")
    if p ~= "" then table.insert(paths, p) end
  end
  return paths
end

-- Basic fuzzy scoring helpers (no plugins)
local function norm(s)
  s = (s or ""):lower()
  s = s:gsub("[^%w%s#@%-_./]", " ") -- keep useful chars for tags/mentions/paths
  s = s:gsub("%s+", " ")
  return s
end

-- subsequence match score: higher is better, -1 if no match
local function fuzzy_subseq_score(q, s)
  if q == "" then return -1 end
  local qi, si = 1, 1
  local score = 0
  local last_match = 0
  while qi <= #q and si <= #s do
    if q:sub(qi, qi) == s:sub(si, si) then
      score = score + 3
      if last_match > 0 then
        local gap = si - last_match
        if gap == 1 then score = score + 2 else score = score - math.min(3, gap) end
      end
      last_match = si
      qi = qi + 1
    end
    si = si + 1
  end
  if qi <= #q then return -1 end
  score = score + math.max(0, 10 - (#s - last_match)) -- small boost if match ends near end
  return score
end

local function split_tokens(q)
  local t = {}
  q = norm(q)
  for w in q:gmatch("%S+") do
    table.insert(t, w)
  end
  return t
end

-- Combined fuzzy score: subsequence of whole query + token coverage + exact substring boosts
local function fuzzy_score(query, hay)
  local qn = norm(query)
  local hn = norm(hay)
  if qn == "" then return -1 end

  local score = 0

  -- exact substring boost
  local p = hn:find(qn, 1, true)
  if p then score = score + 80 - math.min(60, p) end

  -- whole-query subsequence score
  local s1 = fuzzy_subseq_score(qn:gsub("%s+", ""), hn:gsub("%s+", ""))
  if s1 > 0 then score = score + s1 end

  -- token coverage
  local tokens = split_tokens(qn)
  local covered = 0
  for _, tok in ipairs(tokens) do
    local pt = hn:find(tok, 1, true)
    if pt then
      covered = covered + 1
      score = score + 20 - math.min(15, pt)
    else
      -- subseq per-token
      local st = fuzzy_subseq_score(tok, hn)
      if st > 0 then
        score = score + math.floor(st / 2)
      else
        score = score - 10
      end
    end
  end
  score = score + (covered * 10)

  return score
end

local function file_snippet_for_fuzzy(path)
  local name = basename(path)
  local title = read_yaml_title(path)

  -- read only first chunk for performance
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines then
    return name .. " " .. title, {}
  end

  local max_lines = math.min(#lines, 400)
  local parts = { name }
  if title ~= "" then table.insert(parts, title) end

  for i = 1, max_lines do
    parts[#parts + 1] = lines[i]
  end

  -- compact string for scoring
  local blob = table.concat(parts, "\n")

  return blob, lines
end

local function open_fuzzy_picker()
  local orig_win = vim.api.nvim_get_current_win()
  local orig_buf = vim.api.nvim_get_current_buf()
  local orig_view = vim.fn.winsaveview()

  local state = {
    limit_results = 25,     -- you asked for top 25
    pool_limit = 500,       -- candidate pool size (recent newest files); tune if needed
    query = "",             -- set via /
    items = {},             -- {path, name, score}
    idx = 1,

    orig_win = orig_win,
    orig_buf = orig_buf,
    orig_view = orig_view,

    list_win = orig_win,
    list_buf = nil,
    prev_win = nil,
    prev_buf = nil,

    pool = nil,             -- cached recent paths
  }

  local function cleanup()
    if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
      pcall(vim.api.nvim_win_close, state.prev_win, true)
    end
    if vim.api.nvim_win_is_valid(state.orig_win) then
      pcall(vim.api.nvim_set_current_win, state.orig_win)
      if vim.api.nvim_buf_is_valid(state.orig_buf) then
        pcall(vim.api.nvim_win_set_buf, state.orig_win, state.orig_buf)
        pcall(vim.fn.winrestview, state.orig_view)
      end
    end
  end

  local function render_list()
    local header = {
      ("Fuzzy: scope=all(except Archive)  pool=%d  results=%d  query=%s"):format(
        state.pool_limit,
        state.limit_results,
        (state.query ~= "" and state.query or "(set with /)")
      ),
      "------------------------------------------------------------",
      "j/k or arrows = move   Enter = open   / = set query   r = refresh pool   Esc/q = quit",
      "",
    }

    local lines = {}
    for _, h in ipairs(header) do lines[#lines + 1] = h end

    if #state.items == 0 then
      lines[#lines + 1] = (state.query == "") and "Set a query with /" or "No matches."
    else
      for i, it in ipairs(state.items) do
        local marker = (i == state.idx) and ">" or " "
        local label = ("%s %3d) %s  (score=%d)"):format(marker, i, it.name, it.score)
        lines[#lines + 1] = label
      end
    end

    set_buf_lines(state.list_buf, lines)
    local row = 4 + math.max(state.idx, 1)
    pcall(vim.api.nvim_win_set_cursor, state.list_win, { row, 0 })
  end

  local function render_preview()
    if not (state.prev_buf and vim.api.nvim_buf_is_valid(state.prev_buf)) then return end
    if #state.items == 0 then
      set_buf_lines(state.prev_buf, { "No preview." })
      return
    end
    local it = state.items[state.idx]
    if not it or it.path == "" then
      set_buf_lines(state.prev_buf, { "No preview." })
      return
    end

    local ok, file_lines = pcall(vim.fn.readfile, it.path)
    if not ok or not file_lines then
      set_buf_lines(state.prev_buf, { it.path, "------------------------------------------------------------", "(Could not read file)" })
      return
    end

    -- try to find best line match for query (simple substring on normalized)
    local qn = norm(state.query)
    local best_i, best_pos = 1, 999999
    if qn ~= "" then
      for i = 1, math.min(#file_lines, 400) do
        local ln = norm(file_lines[i])
        local pos = ln:find(qn, 1, true)
        if pos and pos < best_pos then
          best_pos = pos
          best_i = i
        end
      end
    end

    local lnum = math.max(1, best_i)
    local start = math.max(1, lnum - 8)
    local stop = math.min(#file_lines, lnum + 8)

    local lines = {
      it.path,
      ("Best match line: %d"):format(lnum),
      "------------------------------------------------------------",
    }

    for i = start, stop do
      local prefix = (i == lnum) and ">>" or "  "
      local num = ("%4d"):format(i)
      lines[#lines + 1] = ("%s %s  %s"):format(prefix, num, file_lines[i])
    end

    set_buf_lines(state.prev_buf, lines)
  end

  local function compute_results()
    if state.query == "" then
      state.items = {}
      state.idx = 1
      return
    end

    if not state.pool then
      state.pool = ps_recent_pool_no_archive(state.pool_limit)
    end

    local scored = {}
    for _, path in ipairs(state.pool) do
      -- score against filename + yaml title + content chunk
      local blob = ""
      local ok = pcall(function()
        blob = file_snippet_for_fuzzy(path)
      end)

      local score
      if ok then
        -- file_snippet_for_fuzzy returns (blob, lines) but we only need blob here
        if type(blob) == "table" then
          -- safety: if something odd happened
          blob = basename(path)
        end
        score = fuzzy_score(state.query, blob)
      else
        score = fuzzy_score(state.query, basename(path))
      end

      if score and score > 0 then
        scored[#scored + 1] = { path = path, name = basename(path), score = score }
      end
    end

    table.sort(scored, function(a, b)
      if a.score == b.score then return a.name < b.name end
      return a.score > b.score
    end)

    local top = {}
    for i = 1, math.min(#scored, state.limit_results) do
      top[#top + 1] = scored[i]
    end
    state.items = top
    state.idx = (#state.items == 0) and 1 or math.max(1, math.min(state.idx, #state.items))
  end

  local function refresh()
    compute_results()
    render_list()
    render_preview()
  end

  local function move(delta)
    if #state.items == 0 then return end
    state.idx = math.max(1, math.min(#state.items, state.idx + delta))
    render_list()
    render_preview()
  end

  local function open_selected()
    if #state.items == 0 then return end
    local it = state.items[state.idx]
    if not it or it.path == "" then return end

    local p = vim.fn.fnamemodify(it.path, ":p")

    if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
      pcall(vim.api.nvim_win_close, state.prev_win, true)
      state.prev_win = nil
    end

    vim.api.nvim_set_current_win(state.list_win)
    vim.cmd({ cmd = "edit", args = { p } })
  end

  local function quit()
    cleanup()
  end

  local ok, err = pcall(function()
    if vim.api.nvim_buf_get_name(0) == "" and vim.bo.buftype == "" then
      vim.cmd("enew")
    end

    state.list_buf = buf_scratch("ZetFuzzy")
    vim.api.nvim_win_set_buf(state.list_win, state.list_buf)

    vim.cmd("vsplit")
    state.prev_win = vim.api.nvim_get_current_win()
    state.prev_buf = buf_scratch("ZetFuzzyPreview")
    vim.api.nvim_win_set_buf(state.prev_win, state.prev_buf)

    vim.cmd("wincmd h")
    state.list_win = vim.api.nvim_get_current_win()

    vim.wo[state.list_win].number = false
    vim.wo[state.list_win].relativenumber = false
    vim.wo[state.list_win].cursorline = true

    vim.wo[state.prev_win].number = false
    vim.wo[state.prev_win].relativenumber = false
    vim.wo[state.prev_win].wrap = false

    local mapopts = { buffer = state.list_buf, nowait = true, silent = true }

    vim.keymap.set("n", "j", function() move(1) end, mapopts)
    vim.keymap.set("n", "k", function() move(-1) end, mapopts)
    vim.keymap.set("n", "<Down>", function() move(1) end, mapopts)
    vim.keymap.set("n", "<Up>", function() move(-1) end, mapopts)

    vim.keymap.set("n", "<CR>", open_selected, mapopts)
    vim.keymap.set("n", "<Esc>", quit, mapopts)
    vim.keymap.set("n", "q", quit, mapopts)

    -- refresh pool (rebuild candidate list)
    vim.keymap.set("n", "r", function()
      state.pool = nil
      refresh()
    end, mapopts)

    -- set query (like your other pickers)
    vim.keymap.set("n", "/", function()
      local newq = vim.fn.input("Fuzzy query (blank clears): ", state.query)
      if newq == nil then return end
      state.query = newq
      state.idx = 1
      refresh()
    end, mapopts)

    refresh()
  end)

  if not ok then
    cleanup()
    vim.notify("Fuzzy picker error: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- ============================================================
-- Keymaps: <leader>z = captures/actions
-- ============================================================
vim.keymap.set("n", "<leader>zi", zet_inbox_capture, { desc = "Zet: inbox capture (no open)" })
vim.keymap.set("n", "<leader>zm", function() zet_new_and_open("meeting") end, { desc = "Zet: new meeting" })
vim.keymap.set("n", "<leader>zn", function() zet_new_and_open("note") end,    { desc = "Zet: new note" })
vim.keymap.set("n", "<leader>zs", function() zet_new_and_open("sync") end,    { desc = "Zet: new sync" })
vim.keymap.set("n", "<leader>zp", function() zet_new_and_open("project") end, { desc = "Zet: new project" })
vim.keymap.set("n", "<leader>za", zet_archive_current, { desc = "Zet: archive current (close)" })
vim.keymap.set("n", "<leader>zx", zet_process_menu,    { desc = "Zet: process current (menu)" })

-- ============================================================
-- Keymaps: <leader>f = find/pickers (preview)
-- ============================================================
vim.keymap.set("n", "<leader>fi", function() open_picker("inbox") end,    { desc = "Find: inbox (preview)" })
vim.keymap.set("n", "<leader>fm", function() open_picker("meetings") end, { desc = "Find: meetings (preview)" })
vim.keymap.set("n", "<leader>fn", function() open_picker("notes") end,    { desc = "Find: notes (preview)" })
vim.keymap.set("n", "<leader>fp", function() open_picker("projects") end, { desc = "Find: projects (preview)" })
vim.keymap.set("n", "<leader>fs", function() open_picker("syncs") end,    { desc = "Find: syncs (preview)" })
vim.keymap.set("n", "<leader>fr", function() open_picker("recent") end,   { desc = "Find: recent (all, preview)" })

-- Action items
vim.keymap.set("n", "<leader>fa", function()
  open_actions_picker({ mode = "open" })
end, { desc = "Find: open action items (all)" })

vim.keymap.set("n", "<leader>fA", function()
  local who = vim.fn.input("@person (blank = no filter): ")
  open_actions_picker({ mode = "open", person = (who ~= "" and who or nil) })
end, { desc = "Find: open action items by @person" })

vim.keymap.set("n", "<leader>fx", function()
  open_actions_picker({ mode = "done" })
end, { desc = "Find: done action items" })

-- Fuzzy search (content-aware)
vim.keymap.set("n", "<leader>fg", open_fuzzy_picker, { desc = "Find: fuzzy search (content, preview)" })
