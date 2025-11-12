#!/bin/bash

set -e
set -o pipefail

sudo apt install git
git clone https://github.com/nabinthapaa/dotfiles $HOME/dotfiles

echo "[*] Updating bash config and symlinking configs"

# Create .config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Backup existing .bashrc with a timestamp
if [ -f "$HOME/.bashrc" ]; then
  TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
  mv "$HOME/.bashrc" "$HOME/.bashrc.bak_$TIMESTAMP"
  echo "[*] Existing .bashrc backed up as .bashrc.bak_$TIMESTAMP"
fi

# Check if dotfiles repo exists
if [ ! -d "$HOME/dotfiles" ]; then
  echo "[!] Dotfiles directory not found! Please ensure it is cloned and try again."
  exit 1
fi

# Symlink the dotfiles
declare -a files=(
  ".bashrc"
  ".profile"
  ".config/ghostty"
  ".config/easyeffects"
  ".config/hypr"
  ".config/kanata"
  ".config/tmux"
  ".config/waybar"
  ".config/tmux-sessionizer"
  ".config/xdg-desktop-portal"
  ".config/dunst"
  ".config/rofi"
  ".config/wal"
)

for file in "${files[@]}"; do
  source_file="$HOME/dotfiles/$file"
  target_file="$HOME/$file"

  # Check if source file exists
  if [ ! -f "$source_file" ] && [ ! -d "$source_file" ]; then
    echo "[!] Source file $source_file does not exist. Skipping symlink."
    continue
  fi

  # Check if target file already exists
  if [ -e "$target_file" ]; then
    echo "[!] Target file $target_file already exists. Skipping symlink."
    continue
  fi

  # Symlink the file
  ln -sf "$source_file" "$target_file"
  echo "[*] Symlinked $source_file to $target_file"
done

echo "[*] Configuration setup complete."
