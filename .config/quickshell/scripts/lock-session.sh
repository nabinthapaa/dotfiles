#!/usr/bin/env bash
set -u

qs_config="/home/nabin/dotfiles/.config/quickshell"
log_file="/tmp/quickshell-lock-ipc.log"

lock_via_ipc() {
  qs -p "$qs_config" ipc --newest call lock lock >>"$log_file" 2>&1
}

printf '%s\n' "lock requested at $(date --iso-8601=seconds)" >>"$log_file"

if lock_via_ipc; then
  exit 0
fi

printf '%s\n' "lock ipc unavailable; starting quickshell" >>"$log_file"
qs -d -p "$qs_config" >>"$log_file" 2>&1 || true
sleep 1

if lock_via_ipc; then
  exit 0
fi

printf '%s\n' "quickshell lock failed; falling back to hyprlock" >>"$log_file"
exec hyprlock
