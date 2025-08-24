#!/bin/bash

set -e

echo "[*] Installing base-devel and git (required for building AUR packages)..."
sudo pacman -S --needed base-devel git curl

echo "[*] Cloning dotfiles"
if [ -d  "$HOME/dotfiles/" ]; then 
		echo "[*] Removing old config"
		rm -rf "$HOME/dotfiles"
fi
git clone https://github.com/nabinthapaa/dotfiles "$HOME/dotfiles"
cd "$HOME/dotfiles"

if ! command -v paru &> /dev/null; then
  echo "[*] Cloning and installing paru..."
  cd "$HOME"
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si
  cd "$HOME"
else
  echo "[*] paru already installed, skipping."
fi

cd "$HOME"

echo "[*] Installing Neovim and related tools..."
paru -S --needed neovim lua51 luarocks tmux dunst kanata-bin starship

echo "[*] Installing general tools..."
paru -S --needed ripgrep jq tldr go fzf btop easyeffects lazygit

echo "[*] Installing fonts..."
paru -S --needed ttf-font-awesome ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols

echo "[*] Installing Duolingo web fonts (for Japanese)..."
paru -S --needed adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts

echo "[*] Installing Ghostty terminal..."
paru -S --needed ghostty

echo "[*] Installing Universal Wayland Session Manager(UWSM)..."
paru -S --needed uwsm libnewt

echo "[*] Installing Discord..."
paru -S --needed discord

echo "[*] Installing sound service" 
paru -S --needed pipewire pipewire-pulse wireplumber pavucontrol

echo "[*] Installing Hyprland tools..."
paru -S --needed hyprpaper hyprshot hyprlock wlogout-git rofi-wayland waybar wl-clipboard pywal hypridle

echo "[*] Installing xdg-desktop-portal support..."
paru -S --needed xdg-desktop-portal-gtk xdg-desktop-portal-hyprland

echo "[*] Installing misc media tools..."
paru -S --noconfirm ffmpeg aalib ascii-image-converter-bin

echo "[*] Installing Docker and adding user to docker group..."
paru -S --needed docker docker-compose docker-buildx

# Avoid errors if group already exists
if ! getent group docker > /dev/null; then
    sudo groupadd docker
fi
sudo usermod -aG docker "$USER"

echo "[*] Installing Rust (non-interactive)..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y


echo "[*] Updating bash config and symlinking configs"
mkdir -p "$HOME/.config"
if [ -f "$HOME/.bashrc" ]; then
  mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
fi
ln -sf "$HOME/dotfiles/.bashrc" "$HOME/.bashrc"
ln -sf "$HOME/dotfiles/.profile" "$HOME/.profile"
ln -sf "$HOME/dotfiles/.config/nvim" "$HOME/.config/nvim"
ln -sf "$HOME/dotfiles/.config/ghostty" "$HOME/.config/ghostty"
ln -sf "$HOME/dotfiles/.config/easyeffects" "$HOME/.config/easyeffects"
ln -sf "$HOME/dotfiles/.config/hypr" "$HOME/.config/hypr"
ln -sf "$HOME/dotfiles/.config/kanata" "$HOME/.config/kanata"
ln -sf "$HOME/dotfiles/.config/tmux" "$HOME/.config/tmux"
ln -sf "$HOME/dotfiles/.config/waybar" "$HOME/.config/waybar"
ln -sf "$HOME/dotfiles/.config/tmux-sessionizer" "$HOME/.config/tmux-sessionizer"
ln -sf "$HOME/dotfiles/.config/xdg-desktop-portal" "$HOME/.config/xdg-desktop-portal"
ln -sf "$HOME/dotfiles/.config/dunst" "$HOME/.config/dunst"
ln -sf "$HOME/dotfiles/.config/rofi" "$HOME/.config/rofi"
ln -sf "$HOME/dotfiles/.config/wal" "$HOME/.config/wal"

# install nvm for node
echo "[*] Installing nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm install --lts

echo "[*] Installing zen browser"
paru -S --needed zen-browser-bin

echo "[*] Generating color scheme"
wal -i "$HOME/dotfiles/image/kath.jpg"

echo "[*] Installing tmux sessionizer" 
if [ -d "$HOME/.local/scripts/" ]; then 
		mkdir -p "$HOME/.local/scripts"
fi
curl https://raw.githubusercontent.com/ThePrimeagen/tmux-sessionizer/refs/heads/master/tmux-sessionizer -o $HOME/.local/scripts/tmux-sessionizer
chmod +x $HOME/.local/scripts/tmux-sessionizer

echo "[*] Starting sound service" 
systemctl --user enable --now pipewire
systemctl --user enable --now pipewire-pulse
systemctl --user enable --now wireplumber

# kanata setup 
echo "[*] Setting up kanata"
if ! getent group uinput > /dev/null; then
    sudo groupadd uinput
    echo "[*] Created 'uinput' group."
fi
sudo usermod -aG uinput "$USER"

if ! getent group input > /dev/null; then
    sudo groupadd input
    echo "[*] Created 'uinput' group."
fi
sudo usermod -aG input "$USER"

sudo modprobe uinput
echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf >> /dev/null 
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/99-uinput.rules >> /dev/null
echo 'KERNEL=="event*", SUBSYSTEM=="input", GROUP="input", MODE="660"' | sudo tee /etc/udev/rules.d/99-input.rules >> /dev/null

echo "[*] Reloading udm rules"
sudo udevadm control --reload-rules
sudo udevadm trigger

systemctl --user enable --now hypridle.service

echo "✅ All done! You may need to restart or log out and back in for Docker group changes to take effect."
