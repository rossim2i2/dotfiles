-- ============================================================
-- init.lua (plugin-free Zet workflow on Windows)
--  - <leader>z... = capture/actions
--  - <leader>f... = find/pickers (with preview + Esc to exit)
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
-- Quality of life keymaps
------------------------------------------------------------
-- Buffer navigation
vim.keymap.set("n", "<leader>bn", "<Cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Splits
vim.keymap.set("n", "<leader>sv", "<Cmd>vsplit<CR>", { desc = "Split vertical" })
vim.keymap.set("n", "<leader>sh", "<Cmd>split<CR>", { desc = "Split horizontal" })

-- Visual indent stays selected
vim.keymap.set("v", "<", "<gv", { desc = "Indent left + reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right + reselect" })

-- Better J
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines keep cursor" })

-- Clear search highlight
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
-- Finder UI (preview pane + Esc quits)
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

  -- Build one PowerShell command that returns: Kind|FullPath (sorted globally by LastWriteTime)
  local dir_lines = {}
  for _, k in ipairs(kinds) do
    local d = root .. "\\" .. folders[k]
    table.insert(dir_lines, ("@{Kind='%s'; Dir='%s'}"):format(k, d:gsub("'", "''")))
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
  ]]):format(table.concat(dir_lines, ",\n      "), limit)

  local out = ps_systemlist({ "pwsh", "-NoProfile", "-Command", ps })
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
  -- If we started on the intro/empty buffer, replace it with a real buffer so UI feels clean
  if vim.api.nvim_buf_get_name(0) == "" and vim.bo.buftype == "" then
    vim.cmd("enew")
  end

  local state = {
    kind = kind,
    limit = 100,
    find = "",
    items = {},
    idx = 1,
    tab = vim.api.nvim_get_current_tabpage(),
    list_buf = nil,
    prev_buf = nil,
    list_win = nil,
    prev_win = nil,
    aug = nil,
  }

  -- New tab for modal feel (easy quit)
  vim.cmd("tabnew")
  local picker_tab = vim.api.nvim_get_current_tabpage()

  -- Left: list, Right: preview
  vim.cmd("vsplit")
  state.list_win = vim.api.nvim_get_current_win()
  state.list_buf = buf_scratch("ZetList")
  vim.api.nvim_win_set_buf(state.list_win, state.list_buf)

  vim.cmd("wincmd l")
  state.prev_win = vim.api.nvim_get_current_win()
  state.prev_buf = buf_scratch("ZetPreview")
  vim.api.nvim_win_set_buf(state.prev_win, state.prev_buf)

  -- Window options
  vim.wo[state.list_win].number = false
  vim.wo[state.list_win].relativenumber = false
  vim.wo[state.list_win].cursorline = true
  vim.wo[state.prev_win].number = false
  vim.wo[state.prev_win].relativenumber = false
  vim.wo[state.prev_win].wrap = false

  local function render_list()
    local header = {
      ("Zet Find: %s   limit=%d   filter=%s"):format(state.kind, state.limit, (state.find ~= "" and state.find or "(none)")),
      "------------------------------------------------------------",
      "j/k = move   Enter = open   / = set filter   r = refresh   Esc/q = quit",
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

    -- Keep cursor on the selected line (header is 4 lines; first item starts at 5)
    local row = 4 + math.max(state.idx, 1)
    pcall(vim.api.nvim_win_set_cursor, state.list_win, { row, 0 })
  end

  local function render_preview()
    if #state.items == 0 then
      set_buf_lines(state.prev_buf, { "No preview." })
      return
    end

    local it = state.items[state.idx]
    if not it or it.path == "" then
      set_buf_lines(state.prev_buf, { "No preview." })
      return
    end

    local lines = {}
    table.insert(lines, it.path)
    table.insert(lines, "------------------------------------------------------------")

    local ok, file_lines = pcall(vim.fn.readfile, it.path)
    if not ok or not file_lines then
      table.insert(lines, "(Could not read file)")
      set_buf_lines(state.prev_buf, lines)
      return
    end

    local max = math.min(#file_lines, 120)
    for i = 1, max do
      table.insert(lines, file_lines[i])
    end
    if #file_lines > max then
      table.insert(lines, "…")
    end

    set_buf_lines(state.prev_buf, lines)
  end

  local function refresh()
    local items = ps_list(state.kind, state.limit)
    if state.find ~= "" then
      local f = state.find:lower()
      local filtered = {}
      for _, it in ipairs(items) do
        if it.name:lower():find(f, 1, true) then
          table.insert(filtered, it)
        end
      end
      items = filtered
    end
    state.items = items
    if #state.items == 0 then
      state.idx = 1
    else
      state.idx = math.min(state.idx, #state.items)
      state.idx = math.max(state.idx, 1)
    end
    render_list()
    render_preview()
  end

  local function quit()
    -- close picker tab (brings you back where you were)
    if vim.api.nvim_tabpage_is_valid(picker_tab) then
      vim.cmd("tabclose")
    end
  end

  local function open_selected()
    if #state.items == 0 then return end
    local it = state.items[state.idx]
    if not it or it.path == "" then return end
    local p = vim.fn.fnamemodify(it.path, ":p")
    -- Close picker tab, then open file
    quit()
    vim.schedule(function()
      vim.cmd({ cmd = "edit", args = { p } })
    end)
  end

  local function move(delta)
    if #state.items == 0 then return end
    state.idx = math.max(1, math.min(#state.items, state.idx + delta))
    render_list()
    render_preview()
  end

  -- Local keymaps in list buffer
  local opts = { buffer = state.list_buf, nowait = true, silent = true }

  vim.keymap.set("n", "j", function() move(1) end, opts)
  vim.keymap.set("n", "k", function() move(-1) end, opts)
  vim.keymap.set("n", "<Down>", function() move(1) end, opts)
  vim.keymap.set("n", "<Up>", function() move(-1) end, opts)

  vim.keymap.set("n", "<CR>", open_selected, opts)

  -- ESC and q exit
  vim.keymap.set("n", "<Esc>", quit, opts)
  vim.keymap.set("n", "q", quit, opts)

  -- refresh
  vim.keymap.set("n", "r", refresh, opts)

  -- filter prompt
  vim.keymap.set("n", "/", function()
    local newf = vim.fn.input("Filter (blank clears): ", state.find)
    if newf == nil then return end
    state.find = newf
    state.idx = 1
    refresh()
  end, opts)

  -- Initial load
  refresh()

  -- Put focus on list
  vim.api.nvim_set_current_win(state.list_win)
end

------------------------------------------------------------
-- Keymaps: <leader>z = captures/actions
------------------------------------------------------------
vim.keymap.set("n", "<leader>zi", zet_inbox_capture, { desc = "Zet: inbox capture (no open)" })
vim.keymap.set("n", "<leader>zm", function() zet_new_and_open("meeting") end, { desc = "Zet: new meeting" })
vim.keymap.set("n", "<leader>zn", function() zet_new_and_open("note") end,    { desc = "Zet: new note" })
vim.keymap.set("n", "<leader>zs", function() zet_new_and_open("sync") end,    { desc = "Zet: new sync" })
vim.keymap.set("n", "<leader>zp", function() zet_new_and_open("project") end, { desc = "Zet: new project" })
vim.keymap.set("n", "<leader>za", zet_archive_current, { desc = "Zet: archive current (close)" })
vim.keymap.set("n", "<leader>zx", zet_process_menu,    { desc = "Zet: process current (menu)" })

------------------------------------------------------------
-- Keymaps: <leader>f = find/pickers (preview)
------------------------------------------------------------
vim.keymap.set("n", "<leader>fi", function() open_picker("inbox") end,    { desc = "Find: inbox (preview)" })
vim.keymap.set("n", "<leader>fm", function() open_picker("meetings") end, { desc = "Find: meetings (preview)" })
vim.keymap.set("n", "<leader>fn", function() open_picker("notes") end,    { desc = "Find: notes (preview)" })
vim.keymap.set("n", "<leader>fp", function() open_picker("projects") end, { desc = "Find: projects (preview)" })
vim.keymap.set("n", "<leader>fs", function() open_picker("syncs") end,    { desc = "Find: syncs (preview)" })
vim.keymap.set("n", "<leader>fr", function() open_picker("recent") end,   { desc = "Find: recent (all, preview)" })
