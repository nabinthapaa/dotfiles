#!/usr/bin/env bash

# Options matching your JSON labels and keys
lock="󰌾 Lock"
hibernate="󰒄 Hibernate"
logout="󰍃 Exit"
shutdown="󰐥 Shutdown"
suspend="󰤄 Suspend"
reboot="󰜉 Reboot"

# Variable passed to rofi
options="$lock\n$hibernate\n$logout\n$suspend\n$reboot\n$shutdown"

# Run Rofi
chosen="$(echo -e "$options" | rofi -dmenu -i -p "Power Menu: " -config ~/.config/rofi/config.rasi)"

# Actions
case $chosen in
$lock)
  hyprlock
  ;;
$hibernate)
  systemctl hibernate
  ;;
$logout)
  uwsm stop
  ;;
$shutdown)
  shutdown now
  ;;
$suspend)
  systemctl suspend
  ;;
$reboot)
  systemctl reboot
  ;;
esac
