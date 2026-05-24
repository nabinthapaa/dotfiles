#!/usr/bin/env bash
set -u

private_flag="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/clipboard-private"

if [[ -f "$private_flag" ]]; then
  exit 0
fi

active_window="$(hyprctl activewindow -j 2>/dev/null || true)"
active_class="$(jq -r '.class // ""' <<<"$active_window" 2>/dev/null | tr '[:upper:]' '[:lower:]')"
active_title="$(jq -r '.title // ""' <<<"$active_window" 2>/dev/null | tr '[:upper:]' '[:lower:]')"
active_app="${active_class} ${active_title}"

case "$active_app" in
  *1password*|*bitwarden*|*keepass*|*keepassxc*|*seahorse*|*password*|*pass-*|*pass\ *|*zen-browser*|*firefox*|*chromium*|*google-chrome*|*brave*|*browser*)
    exit 0
    ;;
esac

cliphist store
