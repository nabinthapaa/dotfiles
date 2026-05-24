#!/usr/bin/env bash

set -u

cpu_cache="/tmp/quickshell-system-monitor-cpu-${UID}"
net_cache="/tmp/quickshell-system-monitor-net-${UID}"
now_ms="$(date +%s%3N)"

read_cpu_line() {
  local line="$1"
  set -- ${line}
  local idle=$(( ${5:-0} + ${6:-0} ))
  local total=0
  local value
  for value in "${@:2}"; do
    total=$((total + value))
  done
  printf '%s %s\n' "$total" "$idle"
}

cpu_json="[]"
cpu_total_percent=0
current_cpu="$(grep -E '^cpu[0-9]* ' /proc/stat)"

if [[ -f "$cpu_cache" ]]; then
  cpu_json="$(
    awk '
      FNR == NR {
        prev_total[$1] = $2
        prev_idle[$1] = $3
        next
      }
      {
        name = $1
        if (name !~ /^cpu/) {
          next
        }
        idle = $5 + $6
        total = 0
        for (i = 2; i <= NF; i++) {
          total += $i
        }
        diff_total = total - prev_total[name]
        diff_idle = idle - prev_idle[name]
        usage = diff_total > 0 ? (100 * (diff_total - diff_idle) / diff_total) : 0
        if (name == "cpu") {
          cpu_total = usage
        } else {
          core = substr(name, 4)
          printf "%s{\"core\":%d,\"usage\":%.1f}", sep, core, usage
          sep = ","
        }
      }
      END {
        printf "\nTOTAL %.1f\n", cpu_total
      }
    ' "$cpu_cache" /proc/stat
  )"
  cpu_total_percent="$(printf '%s\n' "$cpu_json" | awk '/^TOTAL / {print $2}')"
  cpu_json="$(printf '[%s]\n' "$(printf '%s\n' "$cpu_json" | sed '/^TOTAL /d')")"
else
  cpu_json="$(
    printf '%s\n' "$current_cpu" |
      awk '$1 != "cpu" { printf "%s{\"core\":%d,\"usage\":0}", sep, substr($1, 4), sep = "," }' |
      sed 's/^/[/' |
      sed 's/$/]/'
  )"
fi

{
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    read -r total idle <<<"$(read_cpu_line "$line")"
    printf '%s %s %s\n' "${line%% *}" "$total" "$idle"
  done <<<"$current_cpu"
} >"$cpu_cache"

read -r mem_total mem_available <<<"$(awk '
  /MemTotal:/ { total = $2 }
  /MemAvailable:/ { available = $2 }
  END { print total * 1024, available * 1024 }
' /proc/meminfo)"
mem_used=$((mem_total - mem_available))
mem_percent="$(awk -v used="$mem_used" -v total="$mem_total" 'BEGIN { if (total > 0) printf "%.1f", used * 100 / total; else printf "0.0" }')"

read -r swap_total swap_free <<<"$(awk '
  /SwapTotal:/ { total = $2 }
  /SwapFree:/ { free = $2 }
  END { print total * 1024, free * 1024 }
' /proc/meminfo)"
swap_used=$((swap_total - swap_free))
swap_percent="$(awk -v used="$swap_used" -v total="$swap_total" 'BEGIN { if (total > 0) printf "%.1f", used * 100 / total; else printf "0.0" }')"

load_json="$(awk '{ printf "[%s,%s,%s]", $1, $2, $3 }' /proc/loadavg)"
uptime_seconds="$(awk '{ print int($1) }' /proc/uptime)"

iface="$(ip route show default 2>/dev/null | awk 'NR == 1 { for (i = 1; i <= NF; i++) if ($i == "dev") print $(i + 1) }')"
if [[ -z "$iface" ]]; then
  iface="$(ls /sys/class/net 2>/dev/null | grep -v '^lo$' | head -n 1 || true)"
fi

rx_bytes=0
tx_bytes=0
rx_rate=0
tx_rate=0
if [[ -n "$iface" && -r "/sys/class/net/$iface/statistics/rx_bytes" ]]; then
  rx_bytes="$(cat "/sys/class/net/$iface/statistics/rx_bytes")"
  tx_bytes="$(cat "/sys/class/net/$iface/statistics/tx_bytes")"

  if [[ -f "$net_cache" ]]; then
    read -r prev_time prev_iface prev_rx prev_tx <"$net_cache" || true
    if [[ "${prev_iface:-}" == "$iface" && "${prev_time:-0}" -lt "$now_ms" ]]; then
      elapsed_ms=$((now_ms - prev_time))
      rx_delta=$((rx_bytes - prev_rx))
      tx_delta=$((tx_bytes - prev_tx))
      if (( elapsed_ms > 0 && rx_delta >= 0 && tx_delta >= 0 )); then
        rx_rate=$((rx_delta * 1000 / elapsed_ms))
        tx_rate=$((tx_delta * 1000 / elapsed_ms))
      fi
    fi
  fi

  printf '%s %s %s %s\n' "$now_ms" "$iface" "$rx_bytes" "$tx_bytes" >"$net_cache"
fi

temp_value=""
if command -v sensors >/dev/null 2>&1; then
  temp_value="$(sensors 2>/dev/null | awk '
    match($0, /\+[0-9]+(\.[0-9]+)?°C/) {
      value = substr($0, RSTART + 1, RLENGTH - 3)
      if (value > max) max = value
    }
    END {
      if (max > 0) printf "%.1f", max
    }
  ')"
fi
if [[ -z "$temp_value" ]]; then
  temp_value="$(awk '
    { value = $1 / 1000; if (value > max && value < 120) max = value }
    END { if (max > 0) printf "%.1f", max }
  ' /sys/class/thermal/thermal_zone*/temp 2>/dev/null || true)"
fi

disk_json="$(
  df -B1 --output=target,size,used,avail,pcent / "$HOME" 2>/dev/null |
    tail -n +2 |
    awk '!seen[$1]++' |
    jq -Rn '
      [inputs
        | capture("^\\s*(?<mount>\\S+)\\s+(?<size>\\d+)\\s+(?<used>\\d+)\\s+(?<available>\\d+)\\s+(?<percent>\\d+)%")
        | {
            mount: .mount,
            size: (.size | tonumber),
            used: (.used | tonumber),
            available: (.available | tonumber),
            percent: (.percent | tonumber)
          }
      ]'
)"

gpu_json="$(
  if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null |
      jq -Rn '
        [inputs
          | select(length > 0)
          | split(", ")
          | {
              name: .[0],
              usage: ((.[1] // "0") | tonumber),
              memoryUsed: ((.[2] // "0") | tonumber * 1048576),
              memoryTotal: ((.[3] // "0") | tonumber * 1048576),
              temperature: ((.[4] // "0") | tonumber)
            }
        ]'
  elif command -v lspci >/dev/null 2>&1; then
    lspci 2>/dev/null |
      awk -F': ' '/VGA compatible controller|3D controller|Display controller/ { print $2 }' |
      jq -Rn '[inputs | select(length > 0) | { name: ., usage: null, memoryUsed: null, memoryTotal: null, temperature: null }]'
  else
    printf '[]\n'
  fi
)"

process_json="$(
  ps -eo pid=,user=,comm=,%cpu=,%mem=,rss=,args= --sort=-%cpu 2>/dev/null |
    head -n 80 |
    jq -Rn '
      [inputs
        | capture("^\\s*(?<pid>\\d+)\\s+(?<user>\\S+)\\s+(?<name>\\S+)\\s+(?<cpu>[0-9.]+)\\s+(?<mem>[0-9.]+)\\s+(?<rss>\\d+)\\s*(?<command>.*)$")
        | {
            pid: (.pid | tonumber),
            user: .user,
            name: .name,
            cpu: (.cpu | tonumber),
            mem: (.mem | tonumber),
            rss: ((.rss | tonumber) * 1024),
            command: .command
          }
      ]'
)"

jq -n \
  --arg now "$now_ms" \
  --arg uptime "$uptime_seconds" \
  --arg cpu "$cpu_total_percent" \
  --argjson cores "$cpu_json" \
  --argjson load "$load_json" \
  --arg memTotal "$mem_total" \
  --arg memUsed "$mem_used" \
  --arg memPercent "$mem_percent" \
  --arg swapTotal "$swap_total" \
  --arg swapUsed "$swap_used" \
  --arg swapPercent "$swap_percent" \
  --arg iface "$iface" \
  --arg rx "$rx_rate" \
  --arg tx "$tx_rate" \
  --arg temp "$temp_value" \
  --argjson gpus "$gpu_json" \
  --argjson disks "$disk_json" \
  --argjson processes "$process_json" \
  '{
    ok: true,
    timestamp: ($now | tonumber),
    uptime: ($uptime | tonumber),
    cpu: {
      usage: ($cpu | tonumber),
      cores: $cores,
      load: $load,
      temperature: (if $temp == "" then null else ($temp | tonumber) end)
    },
    memory: {
      total: ($memTotal | tonumber),
      used: ($memUsed | tonumber),
      percent: ($memPercent | tonumber)
    },
    swap: {
      total: ($swapTotal | tonumber),
      used: ($swapUsed | tonumber),
      percent: ($swapPercent | tonumber)
    },
    network: {
      interface: $iface,
      rxRate: ($rx | tonumber),
      txRate: ($tx | tonumber)
    },
    gpus: $gpus,
    disks: $disks,
    processes: $processes
  }'
