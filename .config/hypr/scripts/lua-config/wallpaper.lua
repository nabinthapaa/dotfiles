local utils = require("lua-config.utils")
local os = os
local string = string
local io = io

local M = {}

local current_wallpaper_path = utils.home .. "/.config/hypr/cache/current_wallpaper"
local hyprpaper_conf = utils.home .. "/.config/hypr/hyprpaper.conf"
local default_wallpaper = utils.home .. "/wallpaper/Dynamic-Wallpapers/Dark/Mountain_dark.png"

local function read_first_line(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local line = f:read("*l")
	f:close()
	if line then
		line = line:gsub("\r", "")
	end
	return line
end

local function write_file(path, content)
	local f = io.open(path, "w")
	if f then
		f:write(content)
		f:close()
		return true
	end
	return false
end

local function file_exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

function M.restore()
	local notify = function(msg)
		utils.notify_send("Wallpaper Restore", msg)
	end

	local wallpaper = read_first_line(current_wallpaper_path)

	if not wallpaper or wallpaper == "" or not file_exists(wallpaper) then
		wallpaper = default_wallpaper
	end

	if not wallpaper or wallpaper == "" or not file_exists(wallpaper) then
		notify("No saved wallpaper found.")
		os.exit(1)
	end

	local _, has_hyprctl = utils.execute_capture("command -v hyprctl")
	if not has_hyprctl then
		notify("hyprctl is not installed.")
		os.exit(1)
	end

	local _, has_hyprpaper = utils.execute_capture("command -v hyprpaper")
	if not has_hyprpaper then
		notify("hyprpaper is not installed.")
		os.exit(1)
	end

	os.execute(
		string.format("mkdir -p '%s' '%s'", current_wallpaper_path:match("(.*)/"), hyprpaper_conf:match("(.*)/"))
	)
	write_file(current_wallpaper_path, wallpaper .. "\n")

	if not utils.pgrep("hyprpaper") then
		os.execute("hyprpaper >/tmp/hyprpaper.log 2>&1 &")
	end

	local monitors_str = ""
	for _ = 1, 5 do
		monitors_str =
			utils.execute_capture("hyprctl monitors -j 2>/dev/null | jq -r '.[] | .name' 2>/dev/null || true")
		if monitors_str ~= "" then
			break
		end
		utils.sleep(0.2)
	end

	if monitors_str == "" then
		notify("No Hyprland monitors found.")
		os.exit(1)
	end

	local monitors = {}
	for m in string.gmatch(monitors_str, "[^\r\n]+") do
		table.insert(monitors, m)
	end

	for _ = 1, 10 do
		local _, ok = utils.execute_capture(string.format("hyprctl hyprpaper preload '%s'", wallpaper))
		if ok then
			break
		end
		utils.sleep(0.2)
	end

	local applied = 0
	for _, monitor in ipairs(monitors) do
		for _ = 1, 5 do
			local _, ok =
				utils.execute_capture(string.format("hyprctl hyprpaper wallpaper '%s,%s'", monitor, wallpaper))
			if ok then
				applied = applied + 1
				break
			end
			utils.sleep(0.2)
		end
	end

	if applied == 0 then
		notify("Hyprpaper did not accept the saved wallpaper.")
		os.exit(1)
	end

	local conf_content = string.format("preload = %s\n", wallpaper)
	for _, monitor in ipairs(monitors) do
		conf_content = conf_content .. string.format("wallpaper = %s,%s\n", monitor, wallpaper)
	end
	conf_content = conf_content .. "splash = false\n"

	write_file(hyprpaper_conf, conf_content)
end

return M
