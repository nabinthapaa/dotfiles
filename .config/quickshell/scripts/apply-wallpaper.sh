#!/usr/bin/env bash

selected_file="${1:-}"

wallpaper_dir="$HOME/wallpaper"
cache_dir="$HOME/.cache/wal"
magick_cache="$HOME/.cache/ImageMagick"
hyprpaper_conf="$HOME/.config/hypr/hyprpaper.conf"
current_wallpaper="$HOME/.config/hypr/cache/current_wallpaper"
matugen_conf="$HOME/.config/matugen/config.toml"

if [[ -z "$selected_file" || ! -f "$selected_file" ]]; then
  notify-send "Wallpaper Error" "Selected wallpaper was not found."
  exit 1
fi

if [[ "$selected_file" != "$wallpaper_dir"/* ]]; then
  notify-send "Wallpaper Error" "Wallpaper must be inside ~/wallpaper."
  exit 1
fi

if ! command -v hyprctl >/dev/null 2>&1; then
  notify-send "Wallpaper Error" "hyprctl is not installed."
  exit 1
fi

monitors="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | .name' 2>/dev/null)"
if [[ -z "$monitors" ]]; then
  notify-send "Wallpaper Error" "No Hyprland monitors found."
  exit 1
fi

mkdir -p "$cache_dir" "$magick_cache" "$(dirname "$current_wallpaper")"
printf '%s\n' "$selected_file" >"$current_wallpaper"

hyprctl hyprpaper preload "$selected_file" >/dev/null 2>&1 || true

applied_monitors=""
while IFS= read -r monitor; do
  [[ -z "$monitor" ]] && continue
  if hyprctl hyprpaper wallpaper "$monitor,$selected_file" >/dev/null 2>&1; then
    applied_monitors="${applied_monitors}${monitor} "
  fi
done <<<"$monitors"

if [[ -z "$applied_monitors" ]]; then
  notify-send "Wallpaper Error" "Hyprpaper did not accept the selected wallpaper."
  exit 1
fi

notify-send "Wallpaper Changed" "Applied to: ${applied_monitors% }"

if command -v wal >/dev/null 2>&1; then
  wal -i "$selected_file" >/dev/null 2>&1 || true
fi

if command -v matugen >/dev/null 2>&1 && [[ -f "$matugen_conf" ]]; then
  matugen image "$selected_file" --prefer saturation --mode dark --config "$matugen_conf" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface gtk-theme "Adwaita" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" >/dev/null 2>&1 || true
fi

if command -v magick >/dev/null 2>&1; then
  file_hash="$(sha256sum "$selected_file" | cut -d ' ' -f1)"
  blurred_hash="$cache_dir/${file_hash}_blurred.png"
  squared_hash="$cache_dir/${file_hash}_square.png"
  notification_hash="$cache_dir/${file_hash}_notification.png"

  read -r width height <<<"$(magick identify -format "%w %h" "$selected_file" 2>/dev/null)"
  if [[ -n "$width" && -n "$height" ]]; then
    min_dim=$((width < height ? width : height))

    [[ -f "$blurred_hash" ]] || magick "$selected_file" -gaussian-blur 0x5 "$blurred_hash" >/dev/null 2>&1 || true
    [[ -f "$blurred_hash" ]] && cp "$blurred_hash" "$cache_dir/blurred_wallpaper.png"

    [[ -f "$squared_hash" ]] || magick "$selected_file" -gravity center -crop "${min_dim}x${min_dim}+0+0" "$squared_hash" >/dev/null 2>&1 || true
    [[ -f "$squared_hash" ]] && cp "$squared_hash" "$cache_dir/square_image.png"

    [[ -f "$notification_hash" ]] || magick "$selected_file" -gravity center -crop "40x40+0+0" "$notification_hash" >/dev/null 2>&1 || true
    [[ -f "$notification_hash" ]] && cp "$notification_hash" "$cache_dir/notification_image.png"
  fi
fi

printf 'preload = %s\n' "$selected_file" >"$hyprpaper_conf"
while IFS= read -r monitor; do
  [[ -z "$monitor" ]] && continue
  printf 'wallpaper = %s,%s\n' "$monitor" "$selected_file" >>"$hyprpaper_conf"
done <<<"$monitors"
printf 'splash = false\n' >>"$hyprpaper_conf"

hyprctl reload >/dev/null 2>&1 || true
notify-send "Lockscreen & Config Updated"
