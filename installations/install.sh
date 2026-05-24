#!/usr/bin/env bash

set -Eeuo pipefail

readonly DOTFILES_REPO="https://github.com/nabinthapaa/dotfiles"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

SCRIPT_REPO_DIR=""
if command -v git >/dev/null 2>&1; then
  SCRIPT_REPO_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
fi
readonly SCRIPT_REPO_DIR
readonly DOTFILES_DIR="${DOTFILES_DIR:-${SCRIPT_REPO_DIR:-$HOME/dotfiles}}"
readonly PARU_BUILD_DIR="${PARU_BUILD_DIR:-$HOME/.cache/paru-build}"

PACMAN_PACKAGES=(
  base-devel
  git
  curl
)

AUR_PACKAGES=(
  neovim
  lua51
  luarocks
  tmux
  dunst
  kanata-bin
  starship
  ripgrep
  jq
  tldr
  go
  fzf
  btop
  easyeffects
  lazygit
  ttf-font-awesome
  ttf-jetbrains-mono-nerd
  ttf-nerd-fonts-symbols
  noto-fonts-emoji
  adobe-source-han-sans-jp-fonts
  adobe-source-han-serif-jp-fonts
  ghostty
  uwsm
  libnewt
  discord
  pipewire
  pipewire-pulse
  wireplumber
  pavucontrol
  hyprland
  hyprpaper
  hyprshot
  hyprlock
  rofi-wayland
  waybar
  wl-clipboard
  cliphist
  wtype
  python-pywal
  hypridle
  quickshell
  matugen
  swaync
  waypaper
  swww
  brightnessctl
  playerctl
  kitty
  thunar
  kdeconnect
  polkit-gnome
  blueman
  xsettingsd
  network-manager-applet
  libnotify
  xdg-utils
  xdg-desktop-portal-gtk
  xdg-desktop-portal-hyprland
  ffmpeg
  aalib
  ascii-image-converter-bin
  docker
  docker-compose
  docker-buildx
  networkmanager
  bluez
  bluez-utils
  zen-browser-bin
)

CONFIG_DIRS=(
  dunst
  easyeffects
  ghostty
  gtk-3.0
  gtk-4.0
  hypr
  kanata
  kitty
  lazygit
  matugen
  nvim
  quickshell
  rofi
  swaync
  systemd
  tmux
  tmux-sessionizer
  uwsm
  vim
  wal
  waybar
  waypaper
  xdg-desktop-portal
  xsettingsd
)

log() {
  printf '\n[*] %s\n' "$*"
}

warn() {
  printf '\n[!] %s\n' "$*" >&2
}

die() {
  printf '\n[ERROR] %s\n' "$*" >&2
  exit 1
}

backup_path() {
  local path="$1"
  local backup

  if [[ ! -e "$path" || -L "$path" ]]; then
    return 0
  fi

  backup="${path}.bak.$(date +%Y%m%d%H%M%S)"
  log "Backing up $path to $backup"
  mv "$path" "$backup"
}

link_path() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    warn "Skipping missing source: $source"
    return 0
  fi

  backup_path "$target"
  ln -sfnT "$source" "$target"
}

require_arch() {
  [[ -r /etc/arch-release ]] || die "This installer only supports Arch Linux and Arch-based systems."
  command -v pacman >/dev/null 2>&1 || die "pacman is required."
  command -v sudo >/dev/null 2>&1 || die "sudo is required."
  [[ "${EUID}" -ne 0 ]] || die "Run this script as your normal user, not root."
}

install_pacman_packages() {
  log "Installing base packages"
  sudo pacman -Syu --needed --noconfirm "${PACMAN_PACKAGES[@]}"
}

sync_dotfiles() {
  log "Syncing dotfiles into $DOTFILES_DIR"

  if [[ -n "$SCRIPT_REPO_DIR" && "$DOTFILES_DIR" == "$SCRIPT_REPO_DIR" ]]; then
    log "Using current dotfiles checkout"
    return 0
  fi

  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    git -C "$DOTFILES_DIR" pull --ff-only
    return 0
  fi

  if [[ -e "$DOTFILES_DIR" ]]; then
    backup_path "$DOTFILES_DIR"
  fi

  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
}

install_paru() {
  if command -v paru >/dev/null 2>&1; then
    log "paru is already installed"
    return 0
  fi

  log "Installing paru from the AUR"
  rm -rf "$PARU_BUILD_DIR"
  git clone https://aur.archlinux.org/paru.git "$PARU_BUILD_DIR"
  (
    cd "$PARU_BUILD_DIR"
    makepkg -si --needed --noconfirm
  )
}

install_aur_packages() {
  log "Installing system and user packages"
  paru -S --needed --noconfirm "${AUR_PACKAGES[@]}"
}

setup_groups() {
  local group

  log "Configuring user groups"
  for group in docker uinput input; do
    if ! getent group "$group" >/dev/null; then
      sudo groupadd "$group"
    fi
    sudo usermod -aG "$group" "$USER"
  done
}

setup_rust() {
  if command -v cargo >/dev/null 2>&1; then
    log "Rust is already installed"
    return 0
  fi

  log "Installing Rust with rustup"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}

setup_shell_and_configs() {
  local config

  log "Symlinking shell and app configs"
  mkdir -p "$HOME/.config"

  link_path "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
  link_path "$DOTFILES_DIR/.profile" "$HOME/.bash_profile"

  for config in "${CONFIG_DIRS[@]}"; do
    link_path "$DOTFILES_DIR/.config/$config" "$HOME/.config/$config"
  done
}

setup_nvm() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    log "Installing nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  else
    log "nvm is already installed"
  fi

  # shellcheck disable=SC1091
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
  nvm install --lts
}

setup_tmux_sessionizer() {
  local target="$HOME/.local/scripts/tmux-sessionizer"

  log "Installing tmux-sessionizer"
  mkdir -p "$(dirname "$target")"
  curl -fsSL https://raw.githubusercontent.com/ThePrimeagen/tmux-sessionizer/refs/heads/master/tmux-sessionizer -o "$target"
  chmod +x "$target"
}

setup_wallpaper_colors() {
  local wallpaper="$DOTFILES_DIR/image/kath.jpg"

  if [[ -f "$wallpaper" ]] && command -v wal >/dev/null 2>&1; then
    log "Generating pywal color scheme"
    wal -i "$wallpaper"
  fi
}

enable_user_service() {
  local service="$1"

  if systemctl --user list-unit-files "$service" >/dev/null 2>&1; then
    systemctl --user enable --now "$service" || warn "Could not enable user service: $service"
  else
    warn "Skipping missing user service: $service"
  fi
}

setup_services() {
  log "Enabling user services"
  enable_user_service pipewire.service
  enable_user_service pipewire-pulse.service
  enable_user_service wireplumber.service
  enable_user_service hypridle.service
}

setup_kanata() {
  log "Configuring uinput rules for kanata"
  sudo modprobe uinput
  printf 'uinput\n' | sudo tee /etc/modules-load.d/uinput.conf >/dev/null
  printf '%s\n' 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' |
    sudo tee /etc/udev/rules.d/99-uinput.rules >/dev/null
  printf '%s\n' 'KERNEL=="event*", SUBSYSTEM=="input", GROUP="input", MODE="660"' |
    sudo tee /etc/udev/rules.d/99-input.rules >/dev/null

  sudo udevadm control --reload-rules
  sudo udevadm trigger
}

main() {
  require_arch
  install_pacman_packages
  sync_dotfiles
  install_paru
  install_aur_packages
  setup_groups
  setup_rust
  setup_shell_and_configs
  setup_nvm
  setup_wallpaper_colors
  setup_tmux_sessionizer
  setup_services
  setup_kanata

  log "All done. Log out and back in for Docker, input, and uinput group changes to take effect."
}

main "$@"
