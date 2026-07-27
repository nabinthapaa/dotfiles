-- -----------------------------------------------
-- Key Bindings
-- See https://wiki.hypr.land/Configuring/Basics/Binds/
-- -----------------------------------------------

local home = os.getenv("HOME")
local dir = home .. "/dotfiles/.config/hypr/lua/keybindings/"

dofile(dir .. "apps.lua")
dofile(dir .. "quickshell.lua")
dofile(dir .. "utilities.lua")
dofile(dir .. "window.lua")
dofile(dir .. "workspaces.lua")
dofile(dir .. "system.lua")
