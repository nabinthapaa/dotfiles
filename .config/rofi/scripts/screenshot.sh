#!/usr/bin/env bash

# ---- Options ----
screen="󰹑 Full Screen"
area="󰆞 Selected Area"
window="󰖲 Active Window"

# ---- Selection ----
options="$screen\n$area\n$window"
chosen="$(echo -e "$options" | rofi -dmenu -i -p "Screenshot: " -config ~/.config/rofi/config.rasi)"

if [ -z "$chosen" ]; then exit; fi

# ---- Setup Paths ----
temp_dir="/tmp"
temp_name="screenshot_selection.png"
temp_file="$temp_dir/$temp_name"
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
final_file="$dir/Screenshot_$(date +%Y%m%d_%H%M%S).png"

# Delete old temp file if it exists to avoid false positives
rm -f "$temp_file"

# ---- Capture using Hyprshot ----
# Using --silent to prevent Hyprshot's own notifications from appearing too early
case $chosen in
$screen)
  hyprshot -m output --silent -f "$temp_name" -o "$temp_dir"
  ;;
$area)
  hyprshot -m region --silent -f "$temp_name" -o "$temp_dir"
  ;;
$window)
  hyprshot -m window --silent -f "$temp_name" -o "$temp_dir"
  ;;
esac

# ---- Wait for file to exist ----
# This ensures Rofi doesn't pop up before the image is actually written to disk
while [ ! -f "$temp_file" ]; do
  sleep 0.2
  # Add a timeout so it doesn't loop forever if you cancel slurp
  ((count++))
  if [ $count -gt 50 ]; then exit; fi
done

# ---- Confirmation Menu ----
confirm_options="󰄬 Save Screenshot\n󰅖 Discard"
confirm_choice="$(echo -e "$confirm_options" | rofi -dmenu -i -p "Save to Pictures?" -config ~/.config/rofi/config.rasi)"

if [ "$confirm_choice" = "󰄬 Save Screenshot" ]; then
  mv "$temp_file" "$final_file"
  wl-copy <"$final_file"
  notify-send "Screenshot Saved" "Saved to $final_file" -i "$final_file"
else
  rm -f "$temp_file"
  notify-send "Screenshot Discarded" "The temporary image was deleted"
fi
