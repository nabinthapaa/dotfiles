local utils = require("lua-config.utils")
local os = os
local string = string

local M = {}

M.qs_config = utils.home .. "/dotfiles/.config/quickshell/"

local function call_target(monitor, target, log_file)
	if not monitor or monitor == "" then
		return false
	end

	local cmd = string.format("quickshell -n -p '%s' ipc call '%s.%s' toggle 2>&1", M.qs_config, target, monitor)
	local output, success, status = utils.execute_capture(cmd)

	utils.append_log(
		log_file,
		string.format("target=%s.%s status=%s output=%s", target, monitor, tostring(status), output)
	)

	if not success then
		return false
	end

	if
		string.find(output, "Target not found", 1, true)
		or string.find(output, "Socket Error", 1, true)
		or string.find(output, "No running instances", 1, true)
	then
		return false
	end

	return true
end

function M.try_ipc(target, log_file)
	local monitor = utils.target_monitor()
	if monitor and monitor ~= "" then
		if call_target(monitor, target, log_file) then
			return true
		end
	end

	local monitors = utils.all_monitors()
	for _, m in ipairs(monitors) do
		if call_target(m, target, log_file) then
			return true
		end
	end

	return false
end

function M.toggle(target, title, log_file)
	local date_output = utils.execute_capture("date --iso-8601=seconds")
	utils.append_log(log_file, string.format("%s helper invoked at %s", target, date_output))

	if M.try_ipc(target, log_file) then
		os.exit(0)
	end

	utils.append_log(log_file, "starting quickshell config")
	utils.pkill("quickshell")
	utils.sleep(0.4)
	os.execute(string.format("quickshell -n -p '%s' >/tmp/quickshell-nabin.log 2>&1 &", M.qs_config))
	utils.sleep(1.2)

	if M.try_ipc(target, log_file) then
		os.exit(0)
	end

	local action = utils.execute_capture(
		string.format(
			"notify-send 'Quickshell %s' 'Could not open %s. Check %s and /tmp/quickshell-nabin.log.' -A 'open=Open File' -A 'copy=Copy Path'",
			title,
			title,
			log_file
		)
	)

	if action == "open" then
		os.execute(string.format("xdg-open '%s' >/dev/null 2>&1 &", log_file))
	elseif action == "copy" then
		os.execute(string.format("printf '%%s' '%s' | wl-copy", log_file))
	end

	os.exit(1)
end

function M.restart()
	utils.notify_send("Quickshell", "Restarting Quickshell...")
	utils.pkill("quickshell")
	utils.sleep(0.4)
	os.execute(string.format("quickshell -n -p '%s' >/tmp/quickshell-nabin.log 2>&1 &", M.qs_config))
end

function M.toggle_control_center()
	local CC_TITLE = "quickshell-controlcenter"

	-- Check if it's open
	local is_open, ok = utils.execute_capture(
		string.format("hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.title == \"%s\")' 2>/dev/null", CC_TITLE)
	)

	if ok and is_open ~= "" then
		-- It's open, check if it's focused
		local active_title = utils.execute_capture("hyprctl activewindow -j 2>/dev/null | jq -r '.title' 2>/dev/null")
		if active_title == CC_TITLE then
			os.execute(string.format("hyprctl dispatch closewindow 'title:%s'", CC_TITLE))
		else
			os.execute(string.format("hyprctl dispatch focuswindow 'title:%s'", CC_TITLE))
		end
		return
	end

	-- Not open, toggle it via quickshell
	local monitor = utils.target_monitor()
	os.execute(string.format("quickshell -n -p '%s' ipc call 'controlPanel.%s' toggle", M.qs_config, monitor))
end

return M
