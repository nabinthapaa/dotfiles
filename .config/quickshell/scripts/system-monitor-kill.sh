#!/usr/bin/env bash

set -u

pid="${1:-}"
signal="${2:-TERM}"

if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
  printf '{"ok":false,"error":"Invalid process id."}\n'
  exit 1
fi

case "$signal" in
  TERM|KILL|INT|HUP)
    ;;
  *)
    printf '{"ok":false,"error":"Invalid signal."}\n'
    exit 1
    ;;
esac

if [[ "$pid" -le 1 || "$pid" == "$$" ]]; then
  printf '{"ok":false,"error":"Refusing to kill protected process."}\n'
  exit 1
fi

if ! kill -0 "$pid" 2>/dev/null; then
  printf '{"ok":false,"error":"Process is no longer running."}\n'
  exit 1
fi

if kill "-$signal" "$pid" 2>/dev/null; then
  printf '{"ok":true,"pid":%s,"signal":"%s"}\n' "$pid" "$signal"
  exit 0
fi

printf '{"ok":false,"error":"Could not signal process. Permission denied or process exited."}\n'
exit 1
