#!/usr/bin/env bash
set -u

source_filter="${1:-all}"
query="${2:-}"
token="${3:-0}"

installed_cache="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/packages-installed"
installed_ttl=30

json_error() {
  jq -n --arg token "$token" --arg message "$1" '{ token: $token, error: $message, results: [] }'
}

safe_query() {
  [[ "$query" =~ ^[a-zA-Z0-9@._+:-]*$ ]]
}

refresh_installed_cache() {
  if ! mkdir -p "$(dirname "$installed_cache")" 2>/dev/null; then
    installed_cache="/tmp/quickshell-packages-installed-${UID:-user}"
  fi
  if [[ ! -w "$(dirname "$installed_cache")" ]]; then
    installed_cache="/tmp/quickshell-packages-installed-${UID:-user}"
  fi

  if [[ ! -f "$installed_cache" ]] || [[ $(( $(date +%s) - $(stat -c %Y "$installed_cache" 2>/dev/null || printf 0) )) -gt $installed_ttl ]]; then
    if ! { pacman -Qq 2>/dev/null | sort -u >"$installed_cache"; } 2>/dev/null; then
      installed_cache="/tmp/quickshell-packages-installed-${UID:-user}"
      { pacman -Qq 2>/dev/null | sort -u >"$installed_cache"; } 2>/dev/null || true
    fi
  fi
}

is_installed() {
  grep -Fxq "$1" "$installed_cache" 2>/dev/null
}

official_search() {
  local line repo name version rest desc installed

  pacman -Ss -- "$query" 2>/dev/null | while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    if [[ "$line" != [[:space:]]* ]]; then
      repo="${line%%/*}"
      rest="${line#*/}"
      name="${rest%% *}"
      rest="${rest#* }"
      version="${rest%% *}"
      installed=false
      [[ "$line" == *"[installed"* ]] && installed=true
      IFS= read -r desc || desc=""
      desc="${desc#"${desc%%[![:space:]]*}"}"
      jq -nc \
        --arg name "$name" \
        --arg repository "$repo" \
        --arg version "$version" \
        --arg description "$desc" \
        --argjson installed "$installed" \
        '{ name: $name, source: "official", repository: $repository, version: $version, description: $description, installed: $installed }'
    fi
  done
}

installed_search() {
  local name line version desc repo source

  pacman -Qq 2>/dev/null | while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    if [[ -n "$query" && "$name" != *"$query"* ]]; then
      continue
    fi

    line="$(pacman -Qi -- "$name" 2>/dev/null || true)"
    version="$(awk -F': ' '/^Version[[:space:]]*:/ {print $2; exit}' <<<"$line")"
    desc="$(awk -F': ' '/^Description[[:space:]]*:/ {print $2; exit}' <<<"$line")"
    source="installed"
    repo="installed"
    if pacman -Qm -- "$name" >/dev/null 2>&1; then
      source="aur"
      repo="AUR"
    fi

    jq -nc \
      --arg name "$name" \
      --arg source "$source" \
      --arg repository "$repo" \
      --arg version "$version" \
      --arg description "$desc" \
      '{ name: $name, source: $source, repository: $repository, version: $version, description: $description, installed: true }'
  done
}

aur_search() {
  local encoded response obj pkg_name installed
  encoded="$(jq -rn --arg query "$query" '$query | @uri')"
  response="$(curl -fsSL --connect-timeout 4 --max-time 10 "https://aur.archlinux.org/rpc/v5/search/${encoded}" 2>/dev/null)" || return 1

  jq -c '
    if (.type // "") != "search" or (.results | type) != "array" then
      empty
    else
      .results[] | {
        name: (.Name // ""),
        source: "aur",
        repository: "AUR",
        version: (.Version // ""),
        description: (.Description // ""),
        installed: false,
        aurUrl: ("https://aur.archlinux.org/packages/" + (.Name // "")),
        maintainer: (.Maintainer // ""),
        votes: (.NumVotes // 0),
        popularity: (.Popularity // 0),
        outOfDate: ((.OutOfDate // null) != null),
        lastModified: (.LastModified // null)
      }
    end
  ' <<<"$response" | while IFS= read -r obj; do
    pkg_name="$(jq -r '.name // ""' <<<"$obj")"
    installed=false
    is_installed "$pkg_name" && installed=true
    jq -c --argjson installed "$installed" '.installed = $installed' <<<"$obj"
  done
}

if ! command -v jq >/dev/null 2>&1; then
  json_error "jq is required for package search."
  exit 0
fi

if ! command -v pacman >/dev/null 2>&1; then
  json_error "pacman is not available."
  exit 0
fi

if ! safe_query; then
  json_error "Search contains unsupported characters."
  exit 0
fi

refresh_installed_cache

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

case "$source_filter" in
  installed)
    installed_search >"$tmp"
    ;;
  official)
    [[ -n "$query" ]] && official_search >"$tmp"
    ;;
  aur)
    if [[ -n "$query" ]]; then
      if ! aur_search >"$tmp"; then
        json_error "AUR search failed. Check your network connection."
        exit 0
      fi
    fi
    ;;
  all|"")
    if [[ -n "$query" ]]; then
      official_search >"$tmp"
      aur_search >>"$tmp" || true
    fi
    ;;
  *)
    json_error "Unknown package source filter."
    exit 0
    ;;
esac

jq -s --arg token "$token" '
  {
    token: $token,
    results: (
      map(select((.name // "") != ""))
      | unique_by((.source // "") + "/" + (.name // ""))
      | .[0:80]
    )
  }
' "$tmp"
