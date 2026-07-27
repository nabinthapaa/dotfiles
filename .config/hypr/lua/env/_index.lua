-- -----------------------------------------------
-- Environment Variables
-- -----------------------------------------------

local home = os.getenv("HOME")
local dir = home .. "/dotfiles/.config/hypr/lua/env/"

dofile(dir .. "nvidia.lua")
dofile(dir .. "xdg.lua")
dofile(dir .. "qt.lua")
dofile(dir .. "toolkit.lua")
dofile(dir .. "apps.lua")
dofile(dir .. "cursor.lua")
dofile(dir .. "misc.lua")
