#!/usr/bin/env bash

# Get the active pane's PID
pane_pid=$(tmux display-message -p "#{pane_pid}")

# Get the process running in the pane
cmd=$(ps -o comm= --ppid "$pane_pid" | head -n 1)

# If Neovim is running, set status bar to top, else bottom
if [[ "$cmd" == "nvim" ]]; then
  tmux set-option status-position top
else
  tmux set-option status-position bottom
fi
