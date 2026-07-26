-- -----------------------------------------------
-- Autostart
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- -----------------------------------------------

hl.on("hyprland.start", function()
	-- Update DBUS activation environment for Wayland
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	-- Apply GTK theme
	hl.exec_cmd("~/.config/hypr/scripts/apply-gtk-theme.sh")

	-- Set cursor theme
	hl.exec_cmd("hyprctl setcursor material_cursors 32")

	-- KDE Connect daemon
	hl.exec_cmd("kdeconnectd")

	-- Polkit authentication agent
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

	-- EasyEffects audio processing service
	hl.exec_cmd("easyeffects --gapplication-service")

	-- Restore wallpaper from cached selection and sync hyprpaper.conf
	hl.exec_cmd("~/.config/hypr/scripts/restore-wallpaper.sh")

	-- Launch ghostty on workspace 1 (silent)
	hl.exec_cmd("ghostty", { workspace = "1 silent" })

	-- Launch Zen Browser on workspace 2 (silent)
	hl.exec_cmd("zen-browser-bin", { workspace = "2 silent" })

	-- Start kanata keyboard remapper
	hl.exec_cmd("kanata -c /home/nabin/.config/kanata/config.kbd")

	-- Load cliphist clipboard history watcher
	hl.exec_cmd("wl-paste --watch ~/.config/hypr/scripts/store-clipboard.sh")

	-- Start Quickshell
	hl.exec_cmd("~/.config/hypr/scripts/restart-quickshell.sh 0")
	hl.exec_cmd("~/.config/hypr/scripts/watch-quickshell-monitors.sh")
end)
