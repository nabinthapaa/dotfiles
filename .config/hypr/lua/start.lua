-- -----------------------------------------------
-- Autostart
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- -----------------------------------------------

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("~/.config/hypr/scripts/apply-gtk-theme.sh")
	hl.exec_cmd("hyprctl setcursor material_cursors 32")
	hl.exec_cmd("kdeconnectd")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("easyeffects --gapplication-service")
	hl.exec_cmd("~/.config/hypr/scripts/runner.lua wallpaper")
	hl.exec_cmd("ghostty", { workspace = "1 silent" })
	hl.exec_cmd("zen-browser-bin", { workspace = "2 silent" })
	hl.exec_cmd("kanata -c /home/nabin/.config/kanata/config.kbd")
	hl.exec_cmd("wl-paste --watch ~/.config/hypr/scripts/runner.lua clipboard-store")
	hl.exec_cmd("~/.config/hypr/scripts/runner.lua qs-restart")
end)

hl.on("monitor.added", function()
	hl.exec_cmd("~/.config/hypr/scripts/runner.lua qs-restart")
end)

hl.on("monitor.removed", function()
	hl.exec_cmd("~/.config/hypr/scripts/runner.lua qs-restart")
end)
