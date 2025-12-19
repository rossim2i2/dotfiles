#!/usr/bin/env bash
set -euo pipefail

# Pick an app launcher that exists (Wayland-friendly)
choose() {
  if command -v wofi >/dev/null 2>&1; then
    printf "%s" "$1" | wofi --dmenu --prompt "Power" --width 320 --lines 6
  elif command -v fuzzel >/dev/null 2>&1; then
    printf "%s" "$1" | fuzzel --dmenu --prompt "Power> "
  elif command -v bemenu >/dev/null 2>&1; then
    printf "%s" "$1" | bemenu -p "Power"
  else
    # very minimal fallback
    printf "No launcher found (install wofi/fuzzel/bemenu)\n" >&2
    exit 1
  fi
}

menu=$'Lock\nLogout\nSuspend\nReboot\nShutdown'
action="$(choose "$menu" || true)"

case "$action" in
  Lock)
    # Prefer common lockers; pick what you have
    if command -v swaylock >/dev/null 2>&1; then
      swaylock
    elif command -v hyprlock >/dev/null 2>&1; then
      hyprlock
    else
      notify-send "Power menu" "No lock program found (install swaylock or hyprlock)."
    fi
    ;;
  Logout)
    # Niri: try the native command if present, else fall back to ending the user session.
    if command -v niri >/dev/null 2>&1 && niri msg --help >/dev/null 2>&1; then
      niri msg exit || niri msg action quit
    else
      niri msg action quit
    fi
    ;;
  Suspend)
    systemctl suspend
    ;;
  Reboot)
    systemctl reboot
    ;;
  Shutdown)
    systemctl poweroff
    ;;
  *)
    exit 0
    ;;
esac

