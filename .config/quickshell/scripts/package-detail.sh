#!/usr/bin/env bash
set -u

source_type="${1:-official}"
name="${2:-}"
token="${3:-0}"

json_error() {
  jq -n --arg token "$token" --arg message "$1" '{ token: $token, error: $message }'
}

valid_name() {
  [[ "$name" =~ ^[a-zA-Z0-9@._+:-]+$ ]]
}

json_array_from_words() {
  local value="$1"
  if [[ -z "$value" || "$value" == "None" ]]; then
    jq -nc '[]'
  else
    jq -Rnc --arg value "$value" '$value | split("  ") | map(gsub("^ +| +$"; "")) | map(select(length > 0 and . != "None"))'
  fi
}

pacman_field() {
  awk -F': ' -v key="$1" '$1 ~ key { print $2; exit }' <<<"$2"
}

pacman_detail() {
  local data installed source repository version desc licenses depends optdepends provides conflicts

  installed=false
  source="official"
  data="$(pacman -Qi -- "$name" 2>/dev/null)" && installed=true || data="$(pacman -Si -- "$name" 2>/dev/null || true)"
  if [[ -z "$data" ]]; then
    json_error "Package details were not found."
    return
  fi

  repository="$(pacman_field '^Repository[[:space:]]*$' "$data")"
  if [[ "$installed" == true ]] && pacman -Qm -- "$name" >/dev/null 2>&1; then
    source="aur"
    repository="AUR"
  fi
  [[ -z "$repository" ]] && repository="installed"
  version="$(pacman_field '^Version[[:space:]]*$' "$data")"
  desc="$(pacman_field '^Description[[:space:]]*$' "$data")"
  licenses="$(pacman_field '^Licenses[[:space:]]*$' "$data")"
  depends="$(pacman_field '^Depends On[[:space:]]*$' "$data")"
  optdepends="$(pacman_field '^Optional Deps[[:space:]]*$' "$data")"
  provides="$(pacman_field '^Provides[[:space:]]*$' "$data")"
  conflicts="$(pacman_field '^Conflicts With[[:space:]]*$' "$data")"

  jq -n \
    --arg token "$token" \
    --arg name "$name" \
    --arg source "$source" \
    --arg repository "$repository" \
    --arg version "$version" \
    --arg description "$desc" \
    --argjson installed "$installed" \
    --argjson license "$(json_array_from_words "$licenses")" \
    --argjson depends "$(json_array_from_words "$depends")" \
    --argjson optDepends "$(json_array_from_words "$optdepends")" \
    --argjson provides "$(json_array_from_words "$provides")" \
    --argjson conflicts "$(json_array_from_words "$conflicts")" \
    '{
      token: $token,
      package: {
        name: $name,
        source: $source,
        repository: $repository,
        version: $version,
        description: $description,
        installed: $installed,
        license: $license,
        depends: $depends,
        optDepends: $optDepends,
        provides: $provides,
        conflicts: $conflicts
      }
    }'
}

aur_detail() {
  local response installed
  response="$(curl -fsSLG --connect-timeout 4 --max-time 10 "https://aur.archlinux.org/rpc/v5/info" --data-urlencode "arg[]=$name" 2>/dev/null)" || {
    json_error "AUR details failed. Check your network connection."
    return
  }

  installed=false
  pacman -Q -- "$name" >/dev/null 2>&1 && installed=true

  jq -c --arg token "$token" --argjson installed "$installed" '
    if (.results | type) != "array" or (.results | length) == 0 then
      { token: $token, error: "AUR package details were not found." }
    else
      .results[0] as $p | {
        token: $token,
        package: {
          name: ($p.Name // ""),
          source: "aur",
          repository: "AUR",
          version: ($p.Version // ""),
          description: ($p.Description // ""),
          installed: $installed,
          aurUrl: ("https://aur.archlinux.org/packages/" + ($p.Name // "")),
          maintainer: ($p.Maintainer // ""),
          votes: ($p.NumVotes // 0),
          popularity: ($p.Popularity // 0),
          outOfDate: (($p.OutOfDate // null) != null),
          lastModified: ($p.LastModified // null),
          license: ($p.License // []),
          depends: ($p.Depends // []),
          optDepends: ($p.OptDepends // []),
          provides: ($p.Provides // []),
          conflicts: ($p.Conflicts // [])
        }
      }
    end
  ' <<<"$response"
}

if ! command -v jq >/dev/null 2>&1; then
  json_error "jq is required for package details."
  exit 0
fi

if ! valid_name; then
  json_error "Invalid package name."
  exit 0
fi

case "$source_type" in
  aur) aur_detail ;;
  official|installed|*) pacman_detail ;;
esac
