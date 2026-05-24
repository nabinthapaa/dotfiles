#!/usr/bin/env bash

set -u

current_wallpaper="$HOME/.config/hypr/cache/current_wallpaper"
hyprpaper_conf="$HOME/.config/hypr/hyprpaper.conf"
default_wallpaper="$HOME/wallpaper/Dynamic-Wallpapers/Dark/Mountain_dark.png"

notify_error() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Wallpaper Restore" "$1"
  fi
}

wallpaper=""
if [[ -f "$current_wallpaper" ]]; then
  wallpaper="$(head -n 1 "$current_wallpaper" | tr -d '\r')"
fi

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
  wallpaper="$default_wallpaper"
fi

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
  notify_error "No saved wallpaper found."
  exit 1
fi

if ! command -v hyprctl >/dev/null 2>&1; then
  notify_error "hyprctl is not installed."
  exit 1
fi

if ! command -v hyprpaper >/dev/null 2>&1; then
  notify_error "hyprpaper is not installed."
  exit 1
fi

mkdir -p "$(dirname "$current_wallpaper")" "$(dirname "$hyprpaper_conf")"
printf '%s\n' "$wallpaper" >"$current_wallpaper"

if ! pgrep -x hyprpaper >/dev/null 2>&1; then
  hyprpaper >/tmp/hyprpaper.log 2>&1 &
fi

monitors=""
for _ in 1 2 3 4 5; do
  monitors="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | .name' 2>/dev/null || true)"
  [[ -n "$monitors" ]] && break
  sleep 0.2
done

if [[ -z "$monitors" ]]; then
  notify_error "No Hyprland monitors found."
  exit 1
fi

for _ in 1 2 3 4 5 6 7 8 9 10; do
  hyprctl hyprpaper preload "$wallpaper" >/dev/null 2>&1 && break
  sleep 0.2
done

applied=0
while IFS= read -r monitor; do
  [[ -z "$monitor" ]] && continue
  for _ in 1 2 3 4 5; do
    if hyprctl hyprpaper wallpaper "$monitor,$wallpaper" >/dev/null 2>&1; then
      applied=$((applied + 1))
      break
    fi
    sleep 0.2
  done
done <<<"$monitors"

if (( applied == 0 )); then
  notify_error "Hyprpaper did not accept the saved wallpaper."
  exit 1
fi

{
  printf 'preload = %s\n' "$wallpaper"
  while IFS= read -r monitor; do
    [[ -z "$monitor" ]] && continue
    printf 'wallpaper = %s,%s\n' "$monitor" "$wallpaper"
  done <<<"$monitors"
  printf 'splash = false\n'
} >"$hyprpaper_conf"
