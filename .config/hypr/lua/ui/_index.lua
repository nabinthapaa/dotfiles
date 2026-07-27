local home = os.getenv("HOME")
local dir = home .. "/dotfiles/.config/hypr/lua/ui/"

dofile(dir .. "monitors.lua")
dofile(dir .. "general.lua")
dofile(dir .. "cursor.lua")
dofile(dir .. "input.lua")
dofile(dir .. "decoration.lua")
dofile(dir .. "animations.lua")
dofile(dir .. "layouts.lua")
dofile(dir .. "gestures.lua")
dofile(dir .. "binds.lua")
