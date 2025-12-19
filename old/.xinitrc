#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then

    xrdb -merge $sysresources

fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then

    xrdb -merge "$userresources"

fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

setxkbmap us &
#$HOME/.screenlayout/display.sh
lxsession &
nitrogen --restore &
xsetroot -cursor_name left_ptr
xset +fp /home/mike/.local/share/fonts
xset fp rehash
picom &
nm-applet &
numlockx &
setxkbmap -option caps:escape &
volumeicon &
export AWT_TOOLKIT=MToolkit
export QT_QPA_PLATFORMTHEME=qt5ct
xrandr --output DisplayPort-0 --mode 5120x1440 --rate 119.97 --output DisplayPort-1 --mode 2560x1440 --rate 144 --left-of DisplayPort-0
# exec bspwm
# exec xmonad
exec qtile start
