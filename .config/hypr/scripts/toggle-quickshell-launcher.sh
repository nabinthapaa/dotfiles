#!/usr/bin/env bash

set -euo pipefail

qs_config="$HOME/dotfiles/.config/quickshell/"
monitor="$(hyprctl monitors | awk '/Monitor / { current = $2 } /focused: yes/ { print current; exit }')"

if [[ -z "${monitor}" ]]; then
  monitor="$(hyprctl activeworkspace -j | jq -r '.monitor // empty')"
fi

if [[ -n "${monitor}" ]]; then
  qs -p "${qs_config}" ipc call "appLauncher.${monitor}" toggle
fi
