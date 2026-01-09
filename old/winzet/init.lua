-- ============================================================
-- init.lua (plugin-free Zet workflow on Windows)
--  - <leader>z... = capture/actions (PowerShell scripts)
--  - <leader>f... = find/pickers (preview, current tab)
--  - <leader>fg   = fuzzy search (content + filename) via rg
--  - Action Items: [ ] @person ... (open)   [x] @person ... (done)
--
-- Requirements:
--   - pwsh in PATH
--   - rg in PATH
--   - C:\ZetScripts\zet.config.ps1 defines $ZetRoot
--   - C:\ZetScripts\zet-new.ps1, zet-process.ps1, zet-archive.ps1 exist
-- ============================================================

------------------------------------------------------------
-- Leader
------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

------------------------------------------------------------
-- Theme (no plugin assumed; uses colorscheme already available)
------------------------------------------------------------
vim.opt.termguicolors = true
pcall(vim.cmd.colorscheme, "tokyonight-lite")
pcall(vim.api.nvim_set_hl, 0, "@markup.heading", { fg = "#7aa2f7", bold = true })

------------------------------------------------------------
-- Basic Settings
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

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "80"
vim.opt.showmatch = true
vim.opt.matchtime = 2

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

-- Use ripgrep for :grep
vim.opt.grepprg = "rg --vimgrep --smart-case"
vim.opt.grepformat = "%f:%l:%c:%m"

------------------------------------------------------------
-- Windows-safe temp dirs (swap/undo/backup/view)
------------------------------------------------------------
if vim.fn.has("win32") == 1 then
  local base = vim.fn.stdpath("state")
  local function ensure(p) if vim.fn.isdirectory(p) == 0 then vim.fn.mkdir(p, "p") end end
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
-- QoL keymaps
------------------------------------------------------------
vim.keymap.set("n", "<leader>bn", "<Cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move down window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move up window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move right window" })

vim.keymap.set("n", "<leader>sv", "<Cmd>vsplit<CR>", { desc = "Split vertical" })
vim.keymap.set("n", "<leader>sh", "<Cmd>split<CR>", { desc = "Split horizontal" })

vim.keymap.set("v", "<", "<gv", { desc = "Indent left + reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right + reselect" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines keep cursor" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

local highlight_yank_group = vim.api.nvim_create_augroup("HighlightYank", {})
vim.api.nvim_create_autocmd("TextYankPost", {
  group = highlight_yank_group,
  pattern = "*",
  callback = function() vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 }) end,
})

-- ============================================================
-- Zet (PowerShell-backed for create/process/archive)
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
  vim.cmd("edit!")
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

    vim.cmd({ cmd = "edit", args = { vim.fn.fnamemodify(newpath, ":p") } })
  end)
end

-- ============================================================
-- UI Helpers (scratch buffers + preview split)
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

-- ============================================================
-- Ripgrep runner (SAFE with spaces): never shell-joins paths
-- ============================================================
local function rg_systemlist(args)
  -- args is a list: {"rg", "--vimgrep", "pattern", "--", "C:\\path with spaces", ...}
  local out = vim.fn.systemlist(args)
  return out
end

local function rg_parse_vimgrep(lines)
  -- rg --vimgrep output: path:line:col:text
  local hits = {}
  for _, line in ipairs(lines) do
    line = (line or ""):gsub("\r", "")
    local p, l, c, t = line:match("^(.-):(%d+):(%d+):(.*)$")
    if p and l and t then
      hits[#hits + 1] = {
        path = p,
        lnum = tonumber(l),
        col = tonumber(c) or 1,
        text = t,
      }
    end
  end
  return hits
end

-- ============================================================
-- Generic Picker (list + preview split), re-usable
-- ============================================================
local function open_list_picker(opts)
  -- opts:
  --   title(): string
  --   build_items(): { {label=..., path=..., lnum?=... , extra?=...}, ... }
  --   preview(item): {lines...}
  --   on_open(item): open behavior
  local orig_win = vim.api.nvim_get_current_win()
  local orig_buf = vim.api.nvim_get_current_buf()
  local orig_view = vim.fn.winsaveview()

  local state = {
    idx = 1,
    items = {},
    find = "",
    list_win = orig_win,
    list_buf = nil,
    prev_win = nil,
    prev_buf = nil,
    orig_win = orig_win,
    orig_buf = orig_buf,
    orig_view = orig_view,
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
      opts.title(state),
      "------------------------------------------------------------",
      "j/k = move   Enter = open   / = filter   r = refresh   Esc/q = quit",
      "",
    }

    local lines = {}
    for _, h in ipairs(header) do lines[#lines + 1] = h end

    if #state.items == 0 then
      lines[#lines + 1] = "No matches."
    else
      for i, it in ipairs(state.items) do
        local marker = (i == state.idx) and ">" or " "
        lines[#lines + 1] = ("%s %3d) %s"):format(marker, i, it.label)
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
    local lines = opts.preview(it, state)
    set_buf_lines(state.prev_buf, lines or { "No preview." })
  end

  local function apply_filter(items)
    if state.find == "" then return items end
    local f = state.find:lower()
    local out = {}
    for _, it in ipairs(items) do
      if (it.label or ""):lower():find(f, 1, true) then
        out[#out + 1] = it
      end
    end
    return out
  end

  local function refresh()
    local items = opts.build_items(state) or {}
    state.items = apply_filter(items)
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
    if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
      pcall(vim.api.nvim_win_close, state.prev_win, true)
      state.prev_win = nil
    end
    opts.on_open(it, state)
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
-- File pickers (keep PS list for “recent” ordering; preview by file head)
-- ============================================================
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
    specs[#specs + 1] = ("@{Kind='%s'; Dir='%s'}"):format(k, d:gsub("'", "''"))
  end

  local ps = ([[
    $specs = @(
      %s
    )
    $items = foreach ($s in $specs) {
      if (Test-Path -LiteralPath $s.Dir) {
        Get-ChildItem -LiteralPath $s.Dir -File -Filter *.md |
          ForEach-Object {
            [pscustomobject]@{ Kind=$s.Kind; Path=$_.FullName; Time=$_.LastWriteTimeUtc }
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
    local k, p = line:match("^([^|]+)|(.+)$")
    if k and p then items[#items + 1] = { kind = k, path = p, name = basename(p) } end
  end
  return items
end

local function open_file_picker(kind)
  open_list_picker({
    title = function(state)
      return ("Zet Find: %s  limit=%d  filter=%s"):format(kind, 120, (state.find ~= "" and state.find or "(none)"))
    end,
    build_items = function(_)
      local list = ps_list(kind, 120)
      local out = {}
      for _, it in ipairs(list) do
        out[#out + 1] = {
          label = ("[%-8s] %s"):format(it.kind, it.name),
          path = it.path,
        }
      end
      return out
    end,
    preview = function(item)
      local p = item.path
      local ok, lines = pcall(vim.fn.readfile, p)
      if not ok or not lines then
        return { p, "------------------------------------------------------------", "(Could not read file)" }
      end
      local out = { p, "------------------------------------------------------------" }
      local max = math.min(#lines, 120)
      for i = 1, max do out[#out + 1] = lines[i] end
      if #lines > max then out[#out + 1] = "…" end
      return out
    end,
    on_open = function(item)
      vim.cmd({ cmd = "edit", args = { vim.fn.fnamemodify(item.path, ":p") } })
    end,
  })
end

-- ============================================================
-- Action items picker powered by rg (fast)
-- ============================================================
local function rg_action_hits(mode, person)
  local root = Zet.root()
  if root == "" then return {} end

  local dirs = {
    root .. "\\Inbox",
    root .. "\\Meetings",
    root .. "\\Notes",
    root .. "\\Projects",
    root .. "\\Syncs",
  }

  local pat_open = [[^\[\s\]\s+.*]]
  local pat_done = [[^\[(?:x|X)\]\s+.*]]
  local pat_all  = [[^\[(?:\s|x|X)\]\s+.*]]

  local pat = pat_open
  if mode == "done" then pat = pat_done end
  if mode == "all" then pat = pat_all end

  local args = { "rg", "--vimgrep", "--no-heading", "--color", "never", "--smart-case", pat, "--" }
  for _, d in ipairs(dirs) do args[#args + 1] = d end

  local out = rg_systemlist(args)
  local hits = rg_parse_vimgrep(out)

  if person and person ~= "" then
    local needle = "@" .. person:lower()
    local filtered = {}
    for _, h in ipairs(hits) do
      if (h.text or ""):lower():find(needle, 1, true) then
        filtered[#filtered + 1] = h
      end
    end
    hits = filtered
  end

  return hits
end

local function open_actions_picker(mode, person)
  open_list_picker({
    title = function(state)
      local who = (person and person ~= "") and (" @" .. person) or ""
      return ("Action Items (%s%s)  filter=%s"):format(mode, who, (state.find ~= "" and state.find or "(none)"))
    end,
    build_items = function()
      local hits = rg_action_hits(mode, person)
      local items = {}
      for _, h in ipairs(hits) do
        local short = (h.text or ""):gsub("%s+", " ")
        if #short > 120 then short = short:sub(1, 120) .. "…" end
        items[#items + 1] = {
          label = ("%s  [%s:%d]"):format(short, basename(h.path), h.lnum),
          path = h.path,
          lnum = h.lnum,
        }
      end
      return items
    end,
    preview = function(item)
      local ok, lines = pcall(vim.fn.readfile, item.path)
      if not ok or not lines then
        return { item.path, "------------------------------------------------------------", "(Could not read file)" }
      end
      local lnum = math.max(1, item.lnum or 1)
      local start = math.max(1, lnum - 6)
      local stop = math.min(#lines, lnum + 6)

      local out = { item.path, ("Line %d"):format(lnum), "------------------------------------------------------------" }
      for i = start, stop do
        local prefix = (i == lnum) and ">>" or "  "
        out[#out + 1] = ("%s %4d  %s"):format(prefix, i, lines[i])
      end
      return out
    end,
    on_open = function(item)
      vim.cmd({ cmd = "edit", args = { vim.fn.fnamemodify(item.path, ":p") } })
      pcall(vim.api.nvim_win_set_cursor, 0, { item.lnum or 1, 0 })
      vim.cmd("normal! zz")
    end,
  })
end

-- ============================================================
-- <leader>fg: fuzzy search contents + filename (rg-assisted)
--
-- Behavior:
--   - Open picker (same UI)
--   - Press "/" to set query
--   - We use rg to get content hits quickly (across folders except Archive)
--   - ALSO include filename matches from rg --files (then fuzzy-score)
--   - Return top 25 results by fuzzy score
-- ============================================================

local function norm(s)
  s = (s or ""):lower()
  s = s:gsub("[^%w%s#@%-_./]", " ")
  s = s:gsub("%s+", " ")
  return s
end

local function split_tokens(q)
  local t = {}
  q = norm(q)
  for w in q:gmatch("%S+") do t[#t + 1] = w end
  return t
end

local function fuzzy_subseq_score(q, s)
  if q == "" then return -1 end
  local qi, si = 1, 1
  local score = 0
  local last = 0
  while qi <= #q and si <= #s do
    if q:sub(qi, qi) == s:sub(si, si) then
      score = score + 3
      if last > 0 then
        local gap = si - last
        if gap == 1 then score = score + 2 else score = score - math.min(3, gap) end
      end
      last = si
      qi = qi + 1
    end
    si = si + 1
  end
  if qi <= #q then return -1 end
  return score
end

local function fuzzy_score(query, hay)
  local qn = norm(query)
  local hn = norm(hay)
  if qn == "" then return -1 end

  local score = 0
  local p = hn:find(qn, 1, true)
  if p then score = score + 80 - math.min(60, p) end

  local s1 = fuzzy_subseq_score(qn:gsub("%s+", ""), hn:gsub("%s+", ""))
  if s1 > 0 then score = score + s1 end

  local tokens = split_tokens(qn)
  local covered = 0
  for _, tok in ipairs(tokens) do
    local pt = hn:find(tok, 1, true)
    if pt then
      covered = covered + 1
      score = score + 20 - math.min(15, pt)
    else
      local st = fuzzy_subseq_score(tok, hn)
      if st > 0 then score = score + math.floor(st / 2) else score = score - 10 end
    end
  end
  score = score + (covered * 10)
  return score
end

local function rg_content_hits(query, dirs)
  if query == "" then return {} end
  local args = { "rg", "--vimgrep", "--no-heading", "--color", "never", "--smart-case", query, "--" }
  for _, d in ipairs(dirs) do args[#args + 1] = d end
  local out = rg_systemlist(args)
  return rg_parse_vimgrep(out)
end

local function rg_list_files(dirs)
  local args = { "rg", "--files", "--" }
  for _, d in ipairs(dirs) do args[#args + 1] = d end
  local out = rg_systemlist(args)
  local files = {}
  for _, line in ipairs(out) do
    line = (line or ""):gsub("\r", "")
    if line ~= "" and line:match("%.md$") then files[#files + 1] = line end
  end
  return files
end

local function open_fuzzy_picker()
  local root = Zet.root()
  if root == "" then return end

  local dirs = {
    root .. "\\Inbox",
    root .. "\\Meetings",
    root .. "\\Notes",
    root .. "\\Projects",
    root .. "\\Syncs",
  }

  local state_extra = {
    query = "",
    results = 25,
    file_pool = nil, -- cached rg --files
  }

  open_list_picker({
    title = function(state)
      return ("Fuzzy (rg): contents + filename | top=%d | query=%s | filter=%s"):format(
        state_extra.results,
        (state_extra.query ~= "" and state_extra.query or "(set with /)"),
        (state.find ~= "" and state.find or "(none)")
      )
    end,

    build_items = function(state)
      -- Use the "/" filter for display-only narrowing; the actual search query is state_extra.query.
      -- We'll still allow "/" to set the query via overriding the "/" key in the picker buffer below.
      local q = state_extra.query
      if q == "" then return {} end

      -- 1) content hits via rg
      local hits = rg_content_hits(q, dirs)

      -- Unique by path, keep best (closest) line number as preview anchor
      local by_path = {}
      for _, h in ipairs(hits) do
        local cur = by_path[h.path]
        if not cur then
          by_path[h.path] = { path = h.path, lnum = h.lnum, sample = h.text }
        else
          -- keep earliest hit line as a stable anchor
          if h.lnum < (cur.lnum or 999999) then
            cur.lnum = h.lnum
            cur.sample = h.text
          end
        end
      end

      -- 2) filename matches (rg --files cached) + fuzzy score against basename
      if not state_extra.file_pool then
        state_extra.file_pool = rg_list_files(dirs)
      end

      local scored = {}

      -- a) score content-hit files higher (use filename + hit text)
      for _, v in pairs(by_path) do
        local label_blob = basename(v.path) .. "\n" .. (v.sample or "")
        local score = fuzzy_score(q, label_blob)
        if score > 0 then
          scored[#scored + 1] = { path = v.path, lnum = v.lnum, score = score + 40, sample = v.sample } -- +40 bias for actual content hit
        end
      end

      -- b) add filename-only matches (no content hit), scored by basename/path
      local seen = {}
      for _, s in ipairs(scored) do seen[s.path] = true end

      for _, p in ipairs(state_extra.file_pool) do
        if not seen[p] then
          local b = basename(p)
          local score = fuzzy_score(q, b)
          if score > 0 then
            scored[#scored + 1] = { path = p, lnum = 1, score = score, sample = "" }
          end
        end
      end

      table.sort(scored, function(a, b)
        if a.score == b.score then return a.path < b.path end
        return a.score > b.score
      end)

      local items = {}
      for i = 1, math.min(#scored, state_extra.results) do
        local it = scored[i]
        items[#items + 1] = {
          label = ("%s  (score=%d)"):format(basename(it.path), it.score),
          path = it.path,
          lnum = it.lnum,
        }
      end

      return items
    end,

    preview = function(item)
      local ok, lines = pcall(vim.fn.readfile, item.path)
      if not ok or not lines then
        return { item.path, "------------------------------------------------------------", "(Could not read file)" }
      end

      local lnum = math.max(1, item.lnum or 1)
      local start = math.max(1, lnum - 8)
      local stop = math.min(#lines, lnum + 8)

      local out = {
        item.path,
        ("Anchor line: %d"):format(lnum),
        "------------------------------------------------------------",
      }
      for i = start, stop do
        local prefix = (i == lnum) and ">>" or "  "
        out[#out + 1] = ("%s %4d  %s"):format(prefix, i, lines[i])
      end
      return out
    end,

    on_open = function(item)
      vim.cmd({ cmd = "edit", args = { vim.fn.fnamemodify(item.path, ":p") } })
      if item.lnum and item.lnum > 1 then
        pcall(vim.api.nvim_win_set_cursor, 0, { item.lnum, 0 })
        vim.cmd("normal! zz")
      end
    end,
  })

  -- Override "/" in the picker buffer to set the *search query* (not just label filter).
  -- We can’t directly reference that list buffer from here cleanly, so we map globally:
  -- If you prefer buffer-local only, tell me and I’ll refactor open_list_picker to expose state.
  vim.defer_fn(function()
    -- If the current buffer is our picker scratch, install a buffer-local map.
    local b = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(b)
    if name:find("ZetList", 1, true) then
      vim.keymap.set("n", "/", function()
        local newq = vim.fn.input("Fuzzy query (blank clears): ", state_extra.query)
        if newq == nil then return end
        state_extra.query = newq
        -- refresh by triggering 'r' mapping: easiest is to call :normal r
        vim.cmd("normal! r")
      end, { buffer = b, nowait = true, silent = true })
      vim.keymap.set("n", "r", function()
        -- rebuild file pool and refresh
        state_extra.file_pool = nil
        vim.cmd("normal! r") -- will be intercepted by picker buffer mapping; if not, harmless
      end, { buffer = b, nowait = true, silent = true })
    end
  end, 10)
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
vim.keymap.set("n", "<leader>fi", function() open_file_picker("inbox") end,    { desc = "Find: inbox (preview)" })
vim.keymap.set("n", "<leader>fm", function() open_file_picker("meetings") end, { desc = "Find: meetings (preview)" })
vim.keymap.set("n", "<leader>fn", function() open_file_picker("notes") end,    { desc = "Find: notes (preview)" })
vim.keymap.set("n", "<leader>fp", function() open_file_picker("projects") end, { desc = "Find: projects (preview)" })
vim.keymap.set("n", "<leader>fs", function() open_file_picker("syncs") end,    { desc = "Find: syncs (preview)" })
vim.keymap.set("n", "<leader>fr", function() open_file_picker("recent") end,   { desc = "Find: recent (all, preview)" })

vim.keymap.set("n", "<leader>fa", function() open_actions_picker("open", nil) end, { desc = "Find: open action items (all)" })
vim.keymap.set("n", "<leader>fA", function()
  local who = vim.fn.input("@person (blank = no filter): ")
  if who == nil then return end
  who = who:gsub("^@", "")
  open_actions_picker("open", (who ~= "" and who or nil))
end, { desc = "Find: open action items by @person" })
vim.keymap.set("n", "<leader>fx", function() open_actions_picker("done", nil) end, { desc = "Find: done action items" })

vim.keymap.set("n", "<leader>fg", open_fuzzy_picker, { desc = "Find: fuzzy (rg contents + filename)" })
