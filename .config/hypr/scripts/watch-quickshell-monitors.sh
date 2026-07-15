#!/usr/bin/env bash
set -u

restart_script="$HOME/.config/hypr/scripts/restart-quickshell.sh"
log_file="/tmp/quickshell-monitor-watch.log"

if ! command -v socat >/dev/null 2>&1; then
  printf '%s\n' "socat is required for monitor hotplug watching" >>"$log_file"
  exit 1
fi

printf '%s\n' "watching Hyprland monitor events at $(date --iso-8601=seconds)" >>"$log_file"

while true; do
  socket_path="${XDG_RUNTIME_DIR:-}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

  if [[ -z "${XDG_RUNTIME_DIR:-}" || -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" || ! -S "$socket_path" ]]; then
    printf '%s\n' "Hyprland event socket not found at $(date --iso-8601=seconds)" >>"$log_file"
    sleep 2
    continue
  fi

  socat -U - UNIX-CONNECT:"$socket_path" | while IFS= read -r event; do
    case "$event" in
      monitoradded*|monitorremoved*)
        printf '%s\n' "event: $event" >>"$log_file"
        "$restart_script" 1.0
        ;;
    esac
  done

  printf '%s\n' "Hyprland event socket disconnected at $(date --iso-8601=seconds)" >>"$log_file"
  sleep 1
done
