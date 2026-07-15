[[ -f ~/.bashrc ]] && . ~/.bashrc

# . "$HOME/.local/share/../bin/env"

if uwsm check may-start; then
  exec uwsm start hyprland-uwsm.desktop
fi


# Added by Antigravity CLI installer
export PATH="/home/nabin/.local/bin:$PATH"
