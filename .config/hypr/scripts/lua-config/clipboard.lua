local utils = require("lua-config.utils")
local os = os
local string = string

local M = {}

function M.store()
	local private_flag = (os.getenv("XDG_STATE_HOME") or (utils.home .. "/.local/state"))
		.. "/quickshell/clipboard-private"

	local f = io.open(private_flag, "r")
	if f then
		f:close()
		os.exit(0)
	end

	local active_window = utils.execute_capture("hyprctl activewindow -j 2>/dev/null || true")
	local active_class = utils.execute_capture(
		"jq -r '.class // \"\"' <<<'"
			.. active_window:gsub("'", "'\\''")
			.. "' 2>/dev/null | tr '[:upper:]' '[:lower:]'"
	)
	local active_title = utils.execute_capture(
		"jq -r '.title // \"\"' <<<'"
			.. active_window:gsub("'", "'\\''")
			.. "' 2>/dev/null | tr '[:upper:]' '[:lower:]'"
	)
	local active_app = active_class .. " " .. active_title

	local ignored = {
		"1password",
		"bitwarden",
		"keepass",
		"keepassxc",
		"seahorse",
		"password",
		"pass-",
		"pass ",
	}

	for _, word in ipairs(ignored) do
		if string.find(active_app, word, 1, true) then
			os.exit(0)
		end
	end

	os.execute("cliphist store")
end

return M
