#!/usr/bin/env bash
set -u

wallpaper_file="$HOME/.config/hypr/cache/current_wallpaper"
matugen_conf="$HOME/.config/matugen/config.toml"

if command -v matugen >/dev/null 2>&1 && [[ -f "$matugen_conf" ]]; then
  wallpaper="$(cat "$wallpaper_file" 2>/dev/null || true)"

  if [[ -n "$wallpaper" && -f "$wallpaper" ]]; then
    matugen image "$wallpaper" --prefer saturation --mode dark --config "$matugen_conf" >/dev/null 2>&1 || true
  fi
fi

gsettings set org.gnome.desktop.interface gtk-theme "Adwaita" >/dev/null 2>&1 || true
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" >/dev/null 2>&1 || true
