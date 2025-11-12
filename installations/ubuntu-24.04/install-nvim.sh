#!/bash/bin

set -e

# Install required packages for neovim
sudo apt-get install ninja-build gettext cmake curl build-essential git tmux

# Clone repository and install stable version
# git clone https://github.com/neovim/neovim
# cd neovim
# git checkout stable
# make CMAKE_BUILD_TYPE=RelWithDebInfo
# sudo make install

echo "Installed neovim"

echo "Installing LazyVim"

# Backup existing nvim configurations (required)
if [ -d "~/.config/nvim" ]; then
  mv ~/.config/nvim ~/.config/nvim.bak >>/dev/null
fi

# Optional but recommended: Backup additional nvim directories
if [ -d "~/.local/share/nvim" ]; then
  mv ~/.local/share/nvim ~/.local/share/nvim.bak >>/dev/null
fi

if [ -d "~/.local/state/nvim" ]; then
  mv ~/.local/state/nvim ~/.local/state/nvim.bak >>/dev/null
fi

if [ -d "~/.cache/nvim" ]; then
  mv ~/.cache/nvim ~/.cache/nvim.bak >>/dev/null
fi

# Clone LazyVim starter into the correct location
git clone https://github.com/LazyVim/starter ~/.config/nvim

# Clean up the .git folder inside LazyVim's starter repo (to prevent tracking)
rm -rf ~/.config/nvim/.git

echo "LazyVim has been installed successfully!"
