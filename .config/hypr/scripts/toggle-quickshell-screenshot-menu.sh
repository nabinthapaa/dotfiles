#!/usr/bin/env bash
set -euo pipefail

qs_config="~/dotfiles/.config/quickshell/"

monitor="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null | head -n 1)"
if [[ -z "${monitor}" ]]; then
  monitor="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.monitor // empty' 2>/dev/null)"
fi
if [[ -z "${monitor}" ]]; then
  monitor="$(hyprctl monitors 2>/dev/null | awk '/Monitor / { current = $2 } /focused: yes/ { print current; exit }')"
fi

if [[ -n "${monitor}" ]]; then
  qs -p "${qs_config}" ipc call "screenshotMenu.${monitor}" toggle
fi
