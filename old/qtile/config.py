import os
import re
import socket
import subprocess
from libqtile import qtile
from libqtile.config import KeyChord, Key, Screen, Group, Drag, Click, Match
from libqtile.command import lazy
from libqtile import layout, bar, widget, hook, extension
from libqtile.lazy import lazy
from typing import List  # noqa: F401

mod = "mod4"                                     # Sets mod key to SUPER/WINDOWS
myTerm = "alacritty"                             # My terminal of choice
myConfig = "/home/mike/.config/qtile/config.py"    # The Qtile config file location

keys = [
         ### The essentials
         Key([mod], "Return",
             lazy.spawn(myTerm),
             desc='Launches My Terminal'
             ),
         Key([mod, "shift"], "Return",
             lazy.spawn("dmenu_run -p 'Run: '"),
             #lazy.spawn("rofi -show drun -config ~/.config/rofi/themes/dt-dmenu.rasi -display-drun \"Run: \" -drun-display-format \"{name}\""),
             desc='Run Launcher'
             ),
         Key([mod], "Tab",
             lazy.layout.down(),
             desc='Toggle through layouts'
             ),
         Key([mod, "shift"], "Tab",
             lazy.layout.client_to_next(),
             desc='Toggle through stacks'
             ),
         Key([mod, "shift"], "c",
             lazy.window.kill(),
             desc='Kill active window'
             ),
         Key([mod, "shift"], "r",
             lazy.restart(),
             desc='Restart Qtile'
             ),
         Key([mod, "shift"], "q",
             lazy.shutdown(),
             desc='Shutdown Qtile'
             ),
         Key(["control", "shift"], "e",
             lazy.spawn("./.dmenu/dmenu-edit-configs.sh"),
             desc='dmenu configs'
             ),
         ### Switch focus to specific monitor (out of three)
         Key([mod], "e",
             lazy.to_screen(0),
             desc='Keyboard focus to monitor 1'
             ),
         Key([mod], "w",
             lazy.to_screen(1),
             desc='Keyboard focus to monitor 2'
             ),
         Key([mod], "r",
             lazy.to_screen(2),
             desc='Keyboard focus to monitor 3'
             ),
         ### Switch focus of monitors
         Key([mod], "period",
             lazy.next_screen(),
             desc='Move focus to next monitor'
             ),
         Key([mod], "comma",
             lazy.prev_screen(),
             desc='Move focus to prev monitor'
             ),
         ### Treetab controls
         Key([mod, "control"], "k",
             lazy.layout.section_up(),
             desc='Move up a section in treetab'
             ),
         Key([mod, "control"], "j",
             lazy.layout.section_down(),
             desc='Move down a section in treetab'
             ),
         ### Window controls
         Key([mod], "equal",
             lazy.layout.grow(),
             lazy.layout.increase_nmaster(),
             desc='Expand window (MonadTall), increase number in master pane (Tile)'
             ),
         Key([mod], "minus",
             lazy.layout.shrink(),
             lazy.layout.decrease_nmaster(),
             desc='Shrink window (MonadTall), decrease number in master pane (Tile)'
             ),
         Key([mod], "n",
             lazy.layout.normalize(),
             desc='normalize window size ratios'
             ),
         Key([mod], "m",
             lazy.layout.maximize(),
             desc='toggle window between minimum and maximum sizes'
             ),
         Key([mod, "shift"], "f",
             lazy.window.toggle_floating(),
             desc='toggle floating'
             ),
         Key([mod, "shift"], "m",
             lazy.window.toggle_fullscreen(),
             desc='toggle fullscreen'
             ),
         Key([mod], "h",
             lazy.layout.left(),
             desc='select window left'
             ),
         Key([mod], "l",
             lazy.layout.right(),
             desc='select window right'
             ),
         Key([mod], "k",
             lazy.layout.up(),
             desc='select window up'
             ),
         Key([mod], "j",
             lazy.layout.down(),
             desc='select window down'
             ),
         Key([mod, "shift"], "h",
             lazy.layout.shuffle_left(),
             desc='move window left'
             ),
         Key([mod, "shift"], "l",
             lazy.layout.shuffle_right(),
             desc='move window right'
             ),
         Key([mod, "shift"], "k",
             lazy.layout.shuffle_up(),
             desc='move window up'
             ),
         Key([mod, "shift"], "j",
             lazy.layout.shuffle_down(),
             desc='move window down'
             ),
         ### Stack controls
         Key([mod, "shift"], "space",
             lazy.layout.rotate(),
             lazy.layout.flip(),
             desc='Switch which side main pane occupies (XmonadTall)'
             ),
         Key([mod], "space",
             lazy.layout.next(),
             desc='Switch window focus to other pane(s) of stack'
             ),
         Key([mod, "control"], "Return",
             lazy.layout.toggle_split(),
             desc='Toggle between split and unsplit sides of stack'
             ),
         ### Dmenu scripts launched with ALT + CTRL + KEY
         Key(["mod1", "control"], "e",
             lazy.spawn("./.dmenu/dmenu-edit-configs.sh"),
             desc='Dmenu script for editing config files'
             ),
         Key(["mod1", "control"], "m",
             lazy.spawn("./.dmenu/dmenu-sysmon.sh"),
             desc='Dmenu system monitor script'
             ),
         Key(["mod1", "control"], "p",
             extension.WindowList(),
             desc='Windowlist'
             ),
         Key(["mod1", "control"], "r",
             desc='Dmenu reddio script'
             ),
         Key(["mod1", "control"], "s",
             lazy.spawn("./.dmenu/dmenu-surfraw.sh"),
             desc='Dmenu surfraw script'
             ),
         Key(["mod1", "control"], "t",
             lazy.spawn("./.dmenu/dmenu-trading.sh"),
             desc='Dmenu trading programs script'
             ),
         Key(["mod1", "control"], "i",
             lazy.spawn("./.dmenu/dmenu-scrot.sh"),
             desc='Dmenu scrot script'
             ),
         ### My applications launched with SUPER + ALT + KEY
         Key([mod, "mod1"], "b",
             lazy.spawn("google-chrome-stable"),
             desc='chrome'
             ),
         Key([mod, "mod1"], "l",
             lazy.spawn(myTerm+" -e lynx gopher://distro.tube"),
             desc='lynx browser'
             ),
         Key([mod, "mod1"], "n",
             lazy.spawn(myTerm+" -e newsboat"),
             desc='newsboat'
             ),
         Key([mod, "mod1"], "r",
             lazy.spawn(myTerm+" -e rtv"),
             desc='reddit terminal viewer'
             ),
         Key([mod, "mod1"], "e",
             lazy.spawn(myTerm+" -e neomutt"),
             desc='neomutt'
             ),
         Key([mod, "mod1"], "m",
             lazy.spawn(myTerm+" -e sh ./scripts/toot.sh"),
             desc='toot mastodon cli'
             ),
         Key([mod, "mod1"], "t",
             lazy.spawn(myTerm+" -e sh ./scripts/tig-script.sh"),
             desc='tig'
             ),
         Key([mod, "mod1"], "f",
             lazy.spawn(myTerm+" -e sh ./.config/vifm/scripts/vifmrun"),
             desc='vifm'
             ),
         Key([mod, "mod1"], "j",
             lazy.spawn(myTerm+" -e joplin"),
             desc='joplin'
             ),
         Key([mod, "mod1"], "c",
             lazy.spawn(myTerm+" -e cmus"),
             desc='cmus'
             ),
         Key([mod, "mod1"], "i",
             lazy.spawn(myTerm+" -e irssi"),
             desc='irssi'
             ),
         Key([mod, "mod1"], "y",
             lazy.spawn(myTerm+" -e youtube-viewer"),
             desc='youtube-viewer'
             ),
         Key([mod, "mod1"], "a",
             lazy.spawn(myTerm+" -e ncpamixer"),
             desc='ncpamixer'
             ),
]

group_names = [("WWW", {'layout': 'monadtall'}),
               ("DEV", {'layout': 'monadtall'}),
               ("SYS", {'layout': 'monadtall'}),
               ("DOC", {'layout': 'monadtall'}),
               ("VBOX", {'layout': 'monadtall'}),
               ("CHAT", {'layout': 'monadtall'}),
               ("WORK", {'layout': 'monadtall'}),
               ("VID", {'layout': 'floating'}),
               ("GFX", {'layout': 'floating'})]

groups = [Group(name, **kwargs) for name, kwargs in group_names]

for i, (name, kwargs) in enumerate(group_names, 1):
    keys.append(Key([mod], str(i), lazy.group[name].toscreen()))        # Switch to another group
    keys.append(Key([mod, "shift"], str(i), lazy.window.togroup(name))) # Send current window to another group

layout_theme = {"border_width": 1,
                "margin": 6,
                "border_focus": "e1acff",
                "border_normal": "1D2330"
                }

layouts = [
    layout.MonadWide(**layout_theme),
    #layout.Bsp(**layout_theme),
    layout.Stack(stacks=2, **layout_theme),
    layout.Columns(num_columns = 3, **layout_theme),
    #layout.RatioTile(**layout_theme),
    #layout.VerticalTile(**layout_theme),
    #layout.Matrix(**layout_theme),
    #layout.Zoomy(**layout_theme),
    layout.MonadTall(**layout_theme),
    layout.Max(**layout_theme),
    #layout.Tile(shift_windows=True, **layout_theme),
    #layout.Stack(num_stacks=2),
    layout.Floating(**layout_theme)
]

colors = [["#0A1318", "#0A1318"], # panel background
          ["#10303C", "#10303C"], # background for current screen tab
          ["#EEEEEE", "#EEEEEE"], # font color for group names
          ["#06175B", "#06175B"], # border line color for current tab
          ["#5B0617", "#5B0617"], # border line color for other tab and odd widgets
          ["#06175B", "#06175B"], # color for the even widgets
          ["#238B09", "#238B09"]] # window name

prompt = "{0}@{1}: ".format(os.environ["USER"], socket.gethostname())

##### DEFAULT WIDGET SETTINGS #####
widget_defaults = dict(
    font="Ubuntu Mono Nerd Font",
    fontsize = 14,
    padding = 2,
    background=colors[2]
)
extension_defaults = widget_defaults.copy()

def init_widgets_list():
    widgets_list = [
              widget.Sep(
                       linewidth = 0,
                       padding = 6,
                       foreground = colors[2],
                       background = colors[0]
                       ),
              widget.Image(
                       #filename = "~/.config/qtile/icons/python.png",
                       filename = "~/.config/qtile/icons/MRCO_Qtile_Logo.jpg",
                       mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn('dmenu_run')}
                       ),
              widget.Sep(
                       linewidth = 0,
                       padding = 6,
                       foreground = colors[2],
                       background = colors[0]
                       ),
              widget.GroupBox(
                       font = "Ubuntu Bold",
                       fontsize = 9,
                       margin_y = 3,
                       margin_x = 0,
                       padding_y = 5,
                       padding_x = 3,
                       borderwidth = 3,
                       #active = colors[2],
                       #inactive = colors[2],
                       active = "#eef9fd",
                       inactive = "#eef9fd",
                       rounded = False,
                       highlight_color = colors[1],
                       highlight_method = "line",
                       this_current_screen_border = colors[3],
                       this_screen_border = colors [4],
                       other_current_screen_border = colors[0],
                       other_screen_border = colors[0],
                       foreground = colors[2],
                       background = colors[0]
                       ),
              widget.Prompt(
                       prompt = prompt,
                       font = "Ubuntu Mono",
                       padding = 10,
                       foreground = colors[3],
                       background = colors[1]
                       ),
              widget.Sep(
                       linewidth = 0,
                       padding = 40,
                       foreground = colors[2],
                       background = colors[0]
                       ),
              widget.WindowName(
                       foreground = colors[6],
                       background = colors[0],
                       padding = 0
                       ),
              widget.Systray(
                       background = colors[0],
                       padding = 5
                       ),
              widget.TextBox(
                       text = u'\uE0B2',
                       background = colors[0],
                       foreground = colors[5],
                       padding = 0,
                       fontsize = 37
                       ),
              widget.TextBox(
                       text = " 🌡",
                       padding = 2,
                       foreground = colors[2],
                       background = colors[5],
                       fontsize = 11
                       ),
              widget.ThermalSensor(
                       foreground = colors[2],
                       background = colors[5],
                       threshold = 90,
                       padding = 5
                       ),
              widget.TextBox(
                       text=u'\uE0B2',
                       background = colors[5],
                       foreground = colors[4],
                       padding = 0,
                       fontsize = 37
                       ),
              widget.CheckUpdates(
                       update_interval = 1800,
                       distro = 'Arch',
                       execute = {'Button1': lambda: qtile.cmd_spawn(myTerm + ' -e sudo pacman -Syu')},
                       # foreground = colors[2],
                       background = colors[4],
                       no_update_string = 'No Updates',
                       colour_have_updates = "#EEEEEE",
                       colour_no_updates = "#EEEEEE"
                       ),
              widget.TextBox(
                       text = u'\uE0B2',
                       background = colors[4],
                       foreground = colors[5],
                       padding = 0,
                       fontsize = 37
                       ),
              widget.Memory(
                       foreground = colors[2],
                       background = colors[5],
                       mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn(myTerm + ' -e htop')},
                       padding = 5
                       ),
              widget.TextBox(
                       text=u'\uE0B2',
                       background = colors[5],
                       foreground = colors[4],
                       padding = 0,
                       fontsize = 37
                       ),
              widget.DF(
                       foreground = colors[2],
                       background = colors[4],
                       padding = 5,
                       visible_on_warn = False,
                       partition = '/home',
                       mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn('pcmanfm')}
                       ),
              widget.DF(
                       foreground = colors[2],
                       background = colors[4],
                       padding = 5,
                       visible_on_warn = False,
                       mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn('pcmanfm')}
                       ),
              widget.TextBox(
                       text = u'\uE0B2',
                       background = colors[4],
                       foreground = colors[5],
                       padding = 0,
                       fontsize = 37
                       ),
              widget.TextBox(
                      text = " Vol:",
                       foreground = colors[2],
                       background = colors[5],
                       padding = 0,
                       mouse_callbacks = {'Button1': lambda: qtile.cmd_spawn('pavucontrol')}
                       ),
              widget.Volume(
                       foreground = colors[2],
                       background = colors[5],
                       padding = 5
                       ),
              widget.TextBox(
                       text = u'\uE0B2',
                       background = colors[5],
                       foreground = colors[4],
                       padding = 0,
                       fontsize = 37
                       ),
              widget.CurrentLayoutIcon(
                       custom_icon_paths = [os.path.expanduser("~/.config/qtile/icons")],
                       foreground = colors[0],
                       background = colors[4],
                       padding = 0,
                       scale = 0.7
                       ),
              widget.CurrentLayout(
                       foreground = colors[2],
                       background = colors[4],
                       padding = 5
                       ),
              widget.TextBox(
                       text = u'\uE0B2',
                       background = colors[4],
                       foreground = colors[5],
                       padding = 0,
                       fontsize = 37
                       ),
              widget.Clock(
                       foreground = colors[2],
                       background = colors[5],
                       format = "%A, %B %d  [ %I:%M %p ]"
                       ),
              widget.Sep(
                       linewidth = 0,
                       padding = 10,
                       foreground = colors[0],
                       background = colors[5]
                       ),
              widget.Systray(
                       background = colors[0],
                       padding = 5
                       ),
              ]
    return widgets_list

def init_widgets_screen1():
    widgets_screen1 = init_widgets_list()
    return widgets_screen1                       # Slicing removes unwanted widgets on Monitors 1,3

def init_screens():
    return [Screen(top=bar.Bar(widgets=init_widgets_screen1(), opacity=1.0, size=20)),
            Screen(top=bar.Bar(widgets=init_widgets_screen1(), opacity=1.0, size=20))]

if __name__ in ["config", "__main__"]:
    screens = init_screens()
    widgets_list = init_widgets_list()
    widgets_screen1 = init_widgets_screen1()

def window_to_prev_group(qtile):
    if qtile.currentWindow is not None:
        i = qtile.groups.index(qtile.currentGroup)
        qtile.currentWindow.togroup(qtile.groups[i - 1].name)

def window_to_next_group(qtile):
    if qtile.currentWindow is not None:
        i = qtile.groups.index(qtile.currentGroup)
        qtile.currentWindow.togroup(qtile.groups[i + 1].name)

def window_to_previous_screen(qtile):
    i = qtile.screens.index(qtile.current_screen)
    if i != 0:
        group = qtile.screens[i - 1].group.name
        qtile.current_window.togroup(group)

def window_to_next_screen(qtile):
    i = qtile.screens.index(qtile.current_screen)
    if i + 1 != len(qtile.screens):
        group = qtile.screens[i + 1].group.name
        qtile.current_window.togroup(group)

def switch_screens(qtile):
    i = qtile.screens.index(qtile.current_screen)
    group = qtile.screens[i - 1].group
    qtile.current_screen.set_group(group)

mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front())
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: List
main = None
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False

floating_layout = layout.Floating(float_rules=[
    *layout.Floating.default_float_rules,
    Match(wm_class='confirmreset'),  # gitk
    Match(wm_class='makebranch'),  # gitk
    Match(wm_class='maketag'),  # gitk
    Match(wm_class='ssh-askpass'),  # ssh-askpass
    Match(title='branchdialog'),  # gitk
    Match(title='pinentry'),  # GPG key password entry
])

auto_fullscreen = True
focus_on_window_activation = "smart"

@hook.subscribe.startup_once
def start_once():
    home = os.path.expanduser('~')
    subprocess.call([home + '/.config/qtile/autostart.sh'])

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"

