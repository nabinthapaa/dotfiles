#!/bin/sh
set -e

# Define versions for Zig and Ghostty
ZIG_VERSION="0.14.1"
ZIG_DIR="/opt/zig"

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing required dependencies..."
sudo apt install -y \
  python3 python3-pip python3-venv git build-essential wget \
  libgtk-4-dev libadwaita-1-dev \
  gettext libxml2-utils pkg-config

# Clean up any old archive
if [ -f "zig-x86_64-linux-$ZIG_VERSION.tar.xz" ]; then
  rm -f "zig-x86_64-linux-$ZIG_VERSION.tar.xz"
fi

# Download Zig
wget "https://ziglang.org/download/$ZIG_VERSION/zig-x86_64-linux-$ZIG_VERSION.tar.xz"

# Extract it
tar -xf "zig-x86_64-linux-$ZIG_VERSION.tar.xz"

# Find extracted directory name dynamically
EXTRACTED_DIR=$(tar -tf "zig-x86_64-linux-$ZIG_VERSION.tar.xz" | head -1 | cut -d/ -f1)

# Remove any existing Zig installation
if [ -d "$ZIG_DIR" ]; then
  sudo rm -rf "$ZIG_DIR"
fi

# Move new Zig to /opt
sudo mv "$EXTRACTED_DIR" "$ZIG_DIR"

# Clean up archive
rm -f "zig-x86_64-linux-$ZIG_VERSION.tar.xz"

# Add Zig to PATH if not already present
if ! grep -q "$ZIG_DIR" ~/.bashrc; then
  echo "export PATH=\$PATH:$ZIG_DIR" >>~/.bashrc
fi

echo "Zig installed to $ZIG_DIR"
echo "Run: source ~/.bashrc && zig version"
