local utils = require("lua-config.utils")
local os = os
local string = string

local M = {}

function M.run()
	if utils.pgrep("gamepad-osk") then
		utils.pkill("gamepad-osk")
		utils.notify_send("Gamepad OSK", "Gamepad OSK disabled.")
		os.exit(0)
	end

	local device = utils.execute_capture(
		"timeout 0.2 evtest 2>&1 | grep -E '^/dev/input/event[0-9]+:\\s*Wireless Controller$' | head -n 1 | cut -d: -f1"
	)

	if device == "" then
		local ev = utils.execute_capture(
			"grep -A 4 -E 'Name=\"Wireless Controller\"' /proc/bus/input/devices | grep -oE 'event[0-9]+' | head -n 1"
		)
		if ev ~= "" then
			device = "/dev/input/" .. ev
		end
	end

	if device == "" then
		utils.notify_send("Gamepad OSK", "Error: Wireless Controller not found!")
		os.exit(1)
	end

	local config_path = ""
	local possible_configs = {
		"configs/config",
		"configs/config.example",
		utils.home .. "/.config/gamepad-osk/config",
	}

	for _, path in ipairs(possible_configs) do
		local f = io.open(path, "r")
		if f then
			f:close()
			config_path = path
			break
		end
	end

	if config_path ~= "" then
		utils.notify_send("Gamepad OSK", "Gamepad OSK enabled: " .. config_path)
		os.execute(
			string.format("exec gamepad-osk --device '%s' --config '%s' --mouse-sensitivity 3", device, config_path)
		)
	else
		print("Using default config...")
		os.execute(string.format("exec gamepad-osk --device '%s'", device))
	end
end

return M
