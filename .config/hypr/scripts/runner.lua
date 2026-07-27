#!/usr/bin/env lua
-- Set package path to include the current directory
local script_dir = arg[0]:match("^(.*)/") or "."
package.path = package.path .. ";" .. script_dir .. "/?.lua"

local action = arg[1]

if not action then
	print("Usage: " .. arg[0] .. " <action>")
	print("Actions:")
	print("  qs-power        Toggle Quickshell Power Menu")
	print("  qs-launcher     Toggle Quickshell Launcher")
	print("  qs-clipboard    Toggle Quickshell Clipboard")
	print("  qs-screenshot   Toggle Quickshell Screenshot Menu")
	print("  qs-system       Toggle Quickshell System Monitor")
	print("  qs-wallpaper    Toggle Quickshell Wallpaper Selector")
	print("  qs-packages     Toggle Quickshell Packages")
	print("  qs-control-center Toggle Quickshell Control Center")
	print("  qs-restart      Restart Quickshell")
	print("  clipboard-store Store clipboard via cliphist (with privacy checks)")
	print("  gamepad         Run Gamepad OSK")
	print("  wallpaper       Restore wallpaper via hyprpaper")
	os.exit(1)
end

if action == "qs-power" then
	return require("lua-config.quickshell").toggle("powerMenu", "Power Menu", "/tmp/quickshell-power-menu-ipc.log")
end

if action == "qs-launcher" then
	return require("lua-config.quickshell").toggle("appLauncher", "Launcher", "/tmp/quickshell-launcher-ipc.log")
end

if action == "qs-clipboard" then
	return require("lua-config.quickshell").toggle(
		"clipboardLauncher",
		"Clipboard",
		"/tmp/quickshell-clipboard-ipc.log"
	)
end

if action == "qs-screenshot" then
	return require("lua-config.quickshell").toggle("screenshotMenu", "Screenshot", "/tmp/quickshell-screenshot-ipc.log")
end

if action == "qs-system" then
	return require("lua-config.quickshell").toggle("systemMonitor", "System Monitor", "/tmp/quickshell-system-ipc.log")
end

if action == "qs-wallpaper" then
	return require("lua-config.quickshell").toggle(
		"wallpaperLauncher",
		"Wallpaper Selector",
		"/tmp/quickshell-wallpaper-ipc.log"
	)
end

if action == "qs-packages" then
	return require("lua-config.quickshell").toggle("packageManager", "Packages", "/tmp/quickshell-packages-ipc.log")
end

if action == "qs-control-center" then
	return require("lua-config.quickshell").toggle_control_center()
end

if action == "qs-restart" then
	return require("lua-config.quickshell").restart()
end

if action == "clipboard-store" then
	return require("lua-config.clipboard").store()
end

if action == "gamepad" then
	return require("lua-config.gamepad").run()
end

if action == "wallpaper" then
	return require("lua-config.wallpaper").restore()
end

print("Unknown action: " .. action)
os.exit(1)
