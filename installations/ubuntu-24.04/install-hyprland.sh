#!/bin/sh

set -e

sudo apt install -y software-properties-common
sudo apt-add-repository -y ppa:cppiber/hyprland

sudo apt install rofi waybar hyprpaper hypridle wlogout hyprlock
