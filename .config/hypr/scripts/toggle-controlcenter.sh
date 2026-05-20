#!/bin/bash
# Toggle Quickshell Control Center

WIN_CLASS="quickshell-controlcenter"

# Check if control center window exists
if hyprctl clients -j | jq -r ".[].title" | grep -q "$WIN_CLASS"; then
    # Window exists, toggle focus
    if hyprctl activewindow -j | jq -r ".title" | grep -q "$WIN_CLASS"; then
        # Currently focused, close it
        hyprctl dispatch closewindow "$WIN_CLASS"
    else
        # Not focused, focus it
        hyprctl dispatch focuswindow "$WIN_CLASS"
    fi
else
    # Window doesn't exist, need to trigger it via Quickshell
    # For now, just notify user
    notify-send "Control Center" "Click the controls icon in the bar"
fi
