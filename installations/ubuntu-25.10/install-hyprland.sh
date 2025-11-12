#!/bin/sh

set -e

sudo apt install -y software-properties-common

echo "Installing hyprland and utilities"
sudo apt install rofi waybar hyprpaper wlogout hyprcursor-util hyprland-protocols hyprwayland-scanner xdg-desktop-portal-hyprland

echo "Installing Kitty terminal..."
sudo apt install -y kitty imagemagick
