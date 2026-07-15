#!/usr/bin/env bash
set -u

qs_config="$HOME/dotfiles/.config/quickshell/"
log_file="/tmp/quickshell-restart.log"
lock_dir="/tmp/quickshell-restart.lock"
delay="${1:-0.5}"

if ! mkdir "$lock_dir" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$lock_dir"' EXIT

printf '%s\n' "restart requested at $(date --iso-8601=seconds)" >>"$log_file"
sleep "$delay"

pkill quickshell >/dev/null 2>&1 || true
sleep 0.4

if command -v qs >/dev/null 2>&1; then
  qs -p "$qs_config" >>"$log_file" 2>&1 &
elif command -v quickshell >/dev/null 2>&1; then
  quickshell -p "$qs_config" >>"$log_file" 2>&1 &
else
  printf '%s\n' "quickshell command not found" >>"$log_file"
  exit 1
fi

printf '%s\n' "quickshell started" >>"$log_file"
