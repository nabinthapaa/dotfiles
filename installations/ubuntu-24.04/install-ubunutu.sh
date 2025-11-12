#!/bin/sh

# Set script to stop on errors
set -e

# Define versions for Zig and Ghostty
ZIG_VERSION="0.14.1"
GHOSTTY_VERSION="1.2.3" # Replace with the version you want to build (e.g., 1.0.0)

# Update and upgrade system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install necessary dependencies
echo "Installing required dependencies..."
sudo apt install -y \
  python3 python3-pip python3-venv git build-essential wget \
  libgtk-4-dev libadwaita-1-dev \
  gettext libxml2-utils pkg-config

# Download and install Zig
echo "Downloading and installing Zig $ZIG_VERSION..."
ZIG_DIR="/opt/zig"
wget "https://ziglang.org/download/$ZIG_VERSION/zig-x86_64-linux-$ZIG_VERSION.tar.xz"
tar -xf "zig-x86_64-linux-$ZIG_VERSION.tar.xz"
sudo mv "zig-x86_64-linux-$ZIG_VERSION.tar.xz" "$ZIG_DIR"
echo "export PATH=\$PATH:$ZIG_DIR" >>~/.bashrc
source ~/.bashrc

# Install Kitty terminal (optional but recommended for terminal-based apps)
echo "Installing Kitty terminal..."
sudo apt install -y kitty

# Download Ghostty source tarball and signature file
echo "Downloading Ghostty source for version $GHOSTTY_VERSION..."
wget "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz"
wget "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz.minisig"

# Optionally verify the downloaded tarball with minisign
# echo "Verifying Ghostty tarball..."
# minisign -Vm ghostty-$GHOSTTY_VERSION.tar.gz -P RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV
#

# Install libgtk4-layer-shell prerequsites
sudo apt install meson ninja-build libwayland-dev wayland-protocols libgtk-4-dev gobject-introspection libgirepository1.0-dev gtk-doc-tools python3 valac
git clone https://github.com/wmww/gtk4-layer-shell.git
cd gtk4-layer-shell
meson setup -Dexamples=true -Ddocs=true -Dtests=true build
ninja -C build
sudo ninja -C build install
sudo ldconfig

# Extract and build Ghostty
echo "Extracting Ghostty source..."
tar -xf "ghostty-$GHOSTTY_VERSION.tar.gz"
cd "ghostty-$GHOSTTY_VERSION/"
echo "Building Ghostty..."
# it will fail add this to build.zig.zon
# .iterm2_themes = .{
#     .url = "https://github.com/mbadolato/iTerm2-Color-Schemes/releases/download/release-20251103-150536-ae86c8c/ghostty-themes.tgz",
#     .hash = "N-V-__8AAPZCAwDJ0OsIn2nbr3FMvBw68oiv-hC2pFuY1eLN",
#     .lazy = true,
# },
zig build -Doptimize=ReleaseFast

# Install Ghostty to $HOME/.local (local user install)
echo "Installing Ghostty locally..."
zig build -p "$HOME/.local" -Doptimize=ReleaseFast

# Add the local bin directory to PATH (if not already in .bashrc)
if ! grep -q "$HOME/.local/bin" ~/.bashrc; then
  echo "export PATH=\$PATH:$HOME/.local/bin" >>~/.bashrc
  source ~/.bashrc
fi

# Optional: Clean up downloaded files
echo "Cleaning up downloaded files..."
rm -f "zig-linux-x86_64-$ZIG_VERSION.tar.xz"
rm -f "ghostty-$GHOSTTY_VERSION.tar.gz" "ghostty-$GHOSTTY_VERSION.tar.gz.minisig"

# Done
echo "Ghostty and dependencies have been installed successfully!"
