#!/bin/sh

set -e

wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip -O ~/Downloads/JetBrainsMono.zip
cd ~/Downloads

unzip JetBrainsMono.zip -d JetBrainsMono

mkdir -p ~/.local/share/fonts
cp JetBrainsMono/*.ttf ~/.local/share/fonts/
fc-cache -fv
