if uwsm check may-start; then
    exec uwsm start hyprland-uwsm.desktop
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc

. "$HOME/.local/share/../bin/env"
