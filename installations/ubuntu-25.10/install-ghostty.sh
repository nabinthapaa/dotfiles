#!/bin/sh

# Set script to stop on errors
set -e

GHOSTTY_VERSION="1.2.3" # Replace with the version you want to build (e.g., 1.0.0)
ZON_FILE="build.zig.zon"

# Define the ITERM2_THEMES block as a single line
ITERM2_THEMES='        .iterm2_themes = .{ .url = "https://github.com/mbadolato/iTerm2-Color-Schemes/releases/download/release-20251103-150536-ae86c8c/ghostty-themes.tgz", .hash = "N-V-__8AAPZCAwDJ0OsIn2nbr3FMvBw68oiv-hC2pFuY1eLN", .lazy = true, },'

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Download Ghostty source tarball and signature file
echo "Downloading Ghostty source for version $GHOSTTY_VERSION..."
wget "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz"
wget "https://release.files.ghostty.org/$GHOSTTY_VERSION/ghostty-$GHOSTTY_VERSION.tar.gz.minisig"

# Optionally verify the downloaded tarball with minisign
# echo "Verifying Ghostty tarball..."
# minisign -Vm ghostty-$GHOSTTY_VERSION.tar.gz -P RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV
#

# Install libgtk4-layer-shell prerequisites
sudo apt install meson ninja-build libwayland-dev wayland-protocols libgtk-4-dev gobject-introspection libgirepository1.0-dev gtk-doc-tools python3 valac libgtk4-layer-shell-dev

# Extract and build Ghostty
echo "Extracting Ghostty source..."
tar -xf "ghostty-$GHOSTTY_VERSION.tar.gz"
cd "ghostty-$GHOSTTY_VERSION/"
echo "Building Ghostty..."

# Remove any existing .iterm2_themes block
sed -i '/\.iterm2_themes = \./,/},/d' "$ZON_FILE"

# Insert the new .iterm2_themes block within the .dependencies block, before .apple_sdk
sed -i "/\.apple_sdk = .{ .path = \".\/pkg\/apple-sdk\" }/i \\
        $ITERM2_THEMES" "$ZON_FILE"

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
rm -rf "ghostty-$GHOSTTY_VERSION.tar.gz" "ghostty-$GHOSTTY_VERSION.tar.gz.minisig" "ghostty-$GHOSTTY_VERSION"

# Done
echo "Ghostty and dependencies have been installed successfully!"
