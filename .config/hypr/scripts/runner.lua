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
    require("lua-config.quickshell").toggle("powerMenu", "Power Menu", "/tmp/quickshell-power-menu-ipc.log")
elseif action == "qs-launcher" then
    require("lua-config.quickshell").toggle("appLauncher", "Launcher", "/tmp/quickshell-launcher-ipc.log")
elseif action == "qs-clipboard" then
    require("lua-config.quickshell").toggle("clipboardLauncher", "Clipboard", "/tmp/quickshell-clipboard-ipc.log")
elseif action == "qs-screenshot" then
    require("lua-config.quickshell").toggle("screenshotMenu", "Screenshot", "/tmp/quickshell-screenshot-ipc.log")
elseif action == "qs-system" then
    require("lua-config.quickshell").toggle("systemMonitor", "System Monitor", "/tmp/quickshell-system-ipc.log")
elseif action == "qs-wallpaper" then
    require("lua-config.quickshell").toggle("wallpaperSelector", "Wallpaper Selector", "/tmp/quickshell-wallpaper-ipc.log")
elseif action == "qs-packages" then
    require("lua-config.quickshell").toggle("packageManager", "Packages", "/tmp/quickshell-packages-ipc.log")
elseif action == "qs-control-center" then
    require("lua-config.quickshell").toggle_control_center()
elseif action == "qs-restart" then
    require("lua-config.quickshell").restart()
elseif action == "clipboard-store" then
    require("lua-config.clipboard").store()
elseif action == "gamepad" then
    require("lua-config.gamepad").run()
elseif action == "wallpaper" then
    require("lua-config.wallpaper").restore()
else
    print("Unknown action: " .. action)
    os.exit(1)
end
