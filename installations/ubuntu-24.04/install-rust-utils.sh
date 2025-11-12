#!/bin/sh

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

source $HOME/.cargo/env

cargo install tealdeer
cargo install starship
cargo install ripgrep
cargo install zoxide

echo 'eval "$(starship init bash)"' >>~/.bashrc
echo 'eval "$(zoxide init bash)"' >>~/.bashrc
