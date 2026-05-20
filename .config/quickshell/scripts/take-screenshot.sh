#!/usr/bin/env bash

mode="${1:-region}"
dir="$HOME/Pictures/Screenshots"
file="Screenshot_$(date +%Y%m%d_%H%M%S).png"
final_file="$dir/$file"

mkdir -p "$dir"

case "$mode" in
  output | region | window) ;;
  *) mode="region" ;;
esac

if ! command -v hyprshot >/dev/null 2>&1; then
  notify-send "Screenshot Error" "hyprshot is not installed."
  exit 1
fi

hyprshot -m "$mode" --silent -f "$file" -o "$dir" >/tmp/quickshell-screenshot.log 2>&1 &
hyprshot_pid=$!

for _ in {1..50}; do
  if [[ -f "$final_file" ]]; then
    break
  fi

  if ! kill -0 "$hyprshot_pid" 2>/dev/null; then
    wait "$hyprshot_pid" 2>/dev/null || true
    [[ -f "$final_file" ]] && break
  fi

  sleep 0.1
done

if [[ ! -f "$final_file" ]]; then
  notify-send "Screenshot Cancelled" "No screenshot was saved."
  exit 0
fi

wl-copy <"$final_file" 2>/dev/null || true

(
  action="$(notify-send "Screenshot Saved" "Saved to $final_file" -i "$final_file" -A "view=View photo")"
  if [[ "$action" == "view" ]]; then
    thunar "$final_file" >/dev/null 2>&1 || thunar "$dir" >/dev/null 2>&1 || xdg-open "$dir" >/dev/null 2>&1 || true
  fi
) &
