local os = os
local io = io
local string = string

local M = {}

M.home = os.getenv("HOME")

function M.append_log(log_file, msg)
	local f = io.open(log_file, "a")
	if f then
		f:write(msg .. "\n")
		f:close()
	end
end

function M.execute_capture(cmd)
	local f = io.popen(cmd)
	if not f then
		return "", false, -1
	end
	local output = f:read("*a") or ""
	local success, reason, status = f:close()

	output = output:gsub("%s+$", "") -- strip trailing whitespace

	local exit_code = 0
	if type(status) == "number" then
		exit_code = status
	elseif not success then
		exit_code = 1
	end

	return output, (success == true), exit_code
end

function M.notify_send(title, message)
	M.execute_capture(string.format("notify-send '%s' '%s' >/dev/null 2>&1", title, message))
end

function M.target_monitor()
	local output = M.execute_capture(
		"hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null | head -n 1"
	)
	return output
end

function M.all_monitors()
	local output = M.execute_capture("hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null")
	local monitors = {}
	for monitor in string.gmatch(output, "[^\r\n]+") do
		table.insert(monitors, monitor)
	end
	return monitors
end

function M.pgrep(name)
	local _, success = M.execute_capture(string.format("pgrep -x '%s' >/dev/null", name))
	return success
end

function M.pkill(name)
	M.execute_capture(string.format("pkill -x '%s' >/dev/null 2>&1", name))
end

function M.sleep(sec)
	os.execute("sleep " .. tostring(sec))
end

return M
