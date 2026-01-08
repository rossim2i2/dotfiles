#!/usr/bin/env bash
set -euo pipefail

# Cache the chosen temp*_input path so we don't rescan sysfs every interval.
CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-temp-input"

preferred_names=(
  k10temp
  coretemp
  thinkpad
  thinkpad_hwmon
  acpitz
)

pick_input_path() {
  local d name f label input

  # Try preferred hwmon names first
  for d in /sys/class/hwmon/hwmon*; do
    [[ -r "$d/name" ]] || continue
    name="$(<"$d/name")"

    for want in "${preferred_names[@]}"; do
      [[ "$name" == "$want" ]] || continue

      # Prefer Tctl if present
      for label in "$d"/temp*_label; do
        [[ -r "$label" ]] || continue
        if [[ "$( <"$label" )" == "Tctl" ]]; then
          input="${label/_label/_input}"
          [[ -r "$input" ]] && { echo "$input"; return 0; }
        fi
      done

      # Otherwise use temp1_input if readable
      [[ -r "$d/temp1_input" ]] && { echo "$d/temp1_input"; return 0; }

      # Or first readable temp*_input
      for f in "$d"/temp*_input; do
        [[ -r "$f" ]] && { echo "$f"; return 0; }
      done
    done
  done

  # Fallback: any readable temp*_input anywhere
  for f in /sys/class/hwmon/hwmon*/temp*_input; do
    [[ -r "$f" ]] && { echo "$f"; return 0; }
  done

  return 1
}

read_c_from_input() {
  local input="$1" v
  v="$(<"$input")"
  echo $(( v / 1000 ))
}

# Use cached path if valid
if [[ -r "$CACHE" ]]; then
  input="$(<"$CACHE")"
  if [[ -r "$input" ]]; then
    echo "$(read_c_from_input "$input")°C"
    exit 0
  fi
fi

# (Re)discover and cache
if input="$(pick_input_path)"; then
  printf '%s' "$input" > "$CACHE"
  echo "$(read_c_from_input "$input")°C"
else
  echo "N/A"
fi
