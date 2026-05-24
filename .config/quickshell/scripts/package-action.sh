#!/usr/bin/env bash
set -u

action="${1:-}"
source_type="${2:-official}"
name="${3:-}"

safe_name='^[a-zA-Z0-9@._+:-]+$'

notify_error() {
  notify-send "Package Searcher" "$1" >/dev/null 2>&1 || true
}

if [[ ! "$name" =~ $safe_name ]]; then
  notify_error "Invalid package name."
  exit 1
fi

terminal=()
if command -v ghostty >/dev/null 2>&1; then
  terminal=(ghostty -e)
elif command -v kitty >/dev/null 2>&1; then
  terminal=(kitty -e)
elif command -v alacritty >/dev/null 2>&1; then
  terminal=(alacritty -e)
elif command -v wezterm >/dev/null 2>&1; then
  terminal=(wezterm start --)
elif command -v foot >/dev/null 2>&1; then
  terminal=(foot)
elif command -v konsole >/dev/null 2>&1; then
  terminal=(konsole -e)
else
  notify_error "No supported terminal found."
  exit 1
fi

aur_helper=""
if command -v paru >/dev/null 2>&1; then
  aur_helper="paru"
elif command -v yay >/dev/null 2>&1; then
  aur_helper="yay"
fi

run_terminal() {
  "${terminal[@]}" bash -lc "$1"
}

pause='printf "\n"; read -r -p "Press Enter to close..."'

case "$action" in
  install)
    if [[ "$source_type" == "aur" ]]; then
      [[ -n "$aur_helper" ]] || { notify_error "Install paru or yay for AUR packages."; exit 1; }
      run_terminal "$aur_helper -S -- '$name'; $pause"
    else
      run_terminal "sudo pacman -S -- '$name'; $pause"
    fi
    ;;
  remove)
    run_terminal "sudo pacman -Rns -- '$name'; $pause"
    ;;
  update)
    if [[ "$source_type" == "aur" ]]; then
      [[ -n "$aur_helper" ]] || { notify_error "Install paru or yay for AUR packages."; exit 1; }
      run_terminal "$aur_helper -S -- '$name'; $pause"
    else
      run_terminal "sudo pacman -S -- '$name'; $pause"
    fi
    ;;
  pkgbuild)
    [[ "$source_type" == "aur" ]] || { notify_error "PKGBUILD is only available for AUR packages."; exit 1; }
    [[ -n "$aur_helper" ]] || { notify_error "Install paru or yay to view AUR PKGBUILDs."; exit 1; }
    run_terminal "$aur_helper -Gp -- '$name' | less -R"
    ;;
  aur-page)
    [[ "$source_type" == "aur" ]] || exit 0
    xdg-open "https://aur.archlinux.org/packages/$name" >/dev/null 2>&1 || notify_error "Could not open AUR page."
    ;;
  copy-name)
    printf '%s' "$name" | wl-copy || notify_error "Could not copy package name."
    ;;
  *)
    notify_error "Unknown package action."
    exit 1
    ;;
esac
