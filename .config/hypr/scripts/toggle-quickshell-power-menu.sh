#!/usr/bin/env bash
set -u

qs_config="~/dotfiles/.config/quickshell/"
log_file="/tmp/quickshell-power-menu-ipc.log"
printf "%s\n" "power menu helper invoked at $(date --iso-8601=seconds)" >>"${log_file}"

target_monitor() {
  hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null | head -n 1
}

all_monitors() {
  hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null
}

call_target() {
  local monitor="$1"
  local output=""
  local status=0

  [[ -z "${monitor}" ]] && return 1

  output="$(qs -p "${qs_config}" ipc call "powerMenu.${monitor}" toggle 2>&1)" || status=$?
  printf "%s\n" "target=powerMenu.${monitor} status=${status} output=${output}" >>"${log_file}"

  if [[ ${status} -ne 0 ]]; then
    return 1
  fi

  if [[ "${output}" == *"Target not found"* || "${output}" == *"Socket Error"* || "${output}" == *"No running instances"* ]]; then
    return 1
  fi

  return 0
}

try_ipc() {
  local monitor
  monitor="$(target_monitor)"

  if call_target "${monitor}"; then
    return 0
  fi

  while IFS= read -r monitor; do
    if call_target "${monitor}"; then
      return 0
    fi
  done < <(all_monitors)

  return 1
}

if try_ipc; then
  exit 0
fi

printf "%s\n" "starting quickshell config" >>"${log_file}"
pkill quickshell >/dev/null 2>&1 || true
sleep 0.4
qs -p "${qs_config}" >/tmp/quickshell-nabin.log 2>&1 &
sleep 1.2

if try_ipc; then
  exit 0
fi

notify-send "Quickshell Power Menu" "Could not open power menu. Check ${log_file} and /tmp/quickshell.log." >/dev/null 2>&1 || true
exit 1
