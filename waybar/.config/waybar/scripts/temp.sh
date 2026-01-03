#!/usr/bin/env bash
set -euo pipefail

# Pick a temperature sensor in a stable way (by hwmon "name").
# Works across many AMD/Intel systems and laptops.

# Preferred hwmon "name" values in order
preferred_names=(
  k10temp          # AMD CPU
  coretemp         # Intel CPU
  thinkpad         # ThinkPad EC (sometimes)
  thinkpad_hwmon   # ThinkPad hwmon
  acpitz           # ACPI thermal zone (fallback; can be weird)
)

find_hwmon_by_name() {
  local want="$1"
  for d in /sys/class/hwmon/hwmon*; do
    [[ -r "$d/name" ]] || continue
    local name
    name="$(<"$d/name")"
    if [[ "$name" == "$want" ]]; then
      echo "$d"
      return 0
    fi
  done
  return 1
}

pick_hwmon() {
  local d
  for n in "${preferred_names[@]}"; do
    if d="$(find_hwmon_by_name "$n")"; then
      echo "$d"
      return 0
    fi
  done
  # Last resort: any hwmon that has a readable temp input
  for d in /sys/class/hwmon/hwmon*; do
    [[ -r "$d/temp1_input" ]] && { echo "$d"; return 0; }
  done
  return 1
}

read_temp_c() {
  local hwmon="$1"

  # Prefer Tctl explicitly
  local f
  for f in "$hwmon"/temp*_label; do
    [[ -r "$f" ]] || continue
    if grep -q '^Tctl$' "$f"; then
      local input="${f/_label/_input}"
      local v
      v="$(<"$input")"
      echo $(( v / 1000 ))
      return 0
    fi
  done

  # Fallback: highest temp (safe default)
  local max=0
  for f in "$hwmon"/temp*_input; do
    [[ -r "$f" ]] || continue
    local v
    v="$(<"$f")"
    (( v > max )) && max="$v"
  done

  (( max > 0 )) && echo $(( max / 1000 )) || echo "N/A"
}

hwmon="$(pick_hwmon)" || { echo "N/A"; exit 0; }
temp_c="$(read_temp_c "$hwmon")" || { echo "N/A"; exit 0; }

# Output for Waybar
echo "${temp_c}°C"

