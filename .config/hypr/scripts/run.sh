#!/bin/bash

if pgrep -x "gamepad-osk" >/dev/null; then
  pkill -x "gamepad-osk"
  notify-send "Gamepad OSK disabled."
  exit 0
fi

# Find Wireless Controller event device
DEVICE=$(timeout 0.2 evtest 2>&1 | grep -E "^/dev/input/event[0-9]+:\s*Wireless Controller$" | head -n 1 | cut -d: -f1)

# Fallback to /proc/bus/input/devices
if [ -z "$DEVICE" ]; then
  EV=$(grep -A 4 -E 'Name="Wireless Controller"' /proc/bus/input/devices | grep -oE 'event[0-9]+' | head -n 1)
  if [ -n "$EV" ]; then
    DEVICE="/dev/input/$EV"
  fi
fi

if [ -z "$DEVICE" ]; then
  notify-send "Error: Wireless Controller not found!"
  exit 1
fi

# Determine config file path
CONFIG_PATH=""
if [ -f "configs/config" ]; then
  CONFIG_PATH="configs/config"
elif [ -f "configs/config.example" ]; then
  CONFIG_PATH="configs/config.example"
elif [ -f "$HOME/.config/gamepad-osk/config" ]; then
  CONFIG_PATH="$HOME/.config/gamepad-osk/config"
fi

if [ -n "$CONFIG_PATH" ]; then
  notify-send "Gamepad OSK enabled: $CONFIG_PATH"
  exec gamepad-osk --device "$DEVICE" --config "$CONFIG_PATH" --mouse-sensitivity 3
else
  echo "Using default config..."
  exec gamepad-osk --device "$DEVICE"
fi
