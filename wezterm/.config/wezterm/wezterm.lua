local wezterm = require("wezterm")
local mux = wezterm.mux

-- Use newer config builder (better errors)
local config = wezterm.config_builder and wezterm.config_builder() or {}

local act = wezterm.action

-- ========== FONT ==========
config.font = wezterm.font({
  family = "MesloLGS Nerd Font Mono",
  weight = "Regular",
})
config.font_size = 12.0

-- ========== WINDOW ==========
config.enable_wayland = true

config.window_decorations = "NONE"
config.window_background_opacity = 0.94

-- Starting size (used if you exit fullscreen)
config.initial_cols = 120
config.initial_rows = 32

-- Padding
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

-- Tabs
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- Scrollback
config.scrollback_lines = 5000

-- Fullscreen
wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

-- ========== SHELL ==========
config.default_prog = { "/bin/bash" }

-- Env
config.set_environment_variables = {
  TERM = "xterm-256color",
}

-- ========== TOKYO NIGHT NIGHT COLORS ==========
config.colors = {
  foreground = "#c0caf5",
  background = "#1a1b26",

  cursor_bg = "#c0caf5",
  cursor_border = "#c0caf5",
  cursor_fg = "#1a1b26",

  selection_bg = "#33467c",
  selection_fg = "#c0caf5",

  ansi = {
    "#15161e",
    "#f7768e",
    "#9ece6a",
    "#e0af68",
    "#7aa2f7",
    "#bb9af7",
    "#7dcfff",
    "#a9b1d6",
  },

  brights = {
    "#414868",
    "#f7768e",
    "#9ece6a",
    "#e0af68",
    "#7aa2f7",
    "#bb9af7",
    "#7dcfff",
    "#c0caf5",
  },
}

-- Frame colors (harmless even fullscreen)
config.window_frame = {
  active_titlebar_bg = "#1a1b26",
  inactive_titlebar_bg = "#1a1b26",
}

-- Dim inactive panes
config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.75,
}

-- Bell
config.audible_bell = "Disabled"

-- ========== KEYBINDINGS ==========
config.keys = {
  -- Clipboard
  { key = "C", mods = "CTRL", action = act.CopyTo("Clipboard") },
  { key = "V", mods = "CTRL", action = act.PasteFrom("Clipboard") },

  -- Fullscreen toggle
  { key = "F11", mods = "NONE", action = act.ToggleFullScreen },

  -- Tabs
  { key = "T", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },

  -- Splits
  { key = "-", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "\\", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Pane navigation
  { key = "H", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Left") },
  { key = "J", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Down") },
  { key = "K", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Up") },
  { key = "L", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Right") },
}

return config

