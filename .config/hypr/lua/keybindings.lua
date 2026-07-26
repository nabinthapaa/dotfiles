-- -----------------------------------------------
-- Key Bindings
-- See https://wiki.hypr.land/Configuring/Basics/Binds/
-- -----------------------------------------------

local mainMod = "SUPER"

-- -----------------------------------------------
-- Applications
-- -----------------------------------------------

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("uwsm app -- ghostty")) -- Open terminal
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("uwsm app -- zen-browser")) -- Open browser
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("uwsm app -- thunar")) -- Open file manager
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("uwsm app -- env ELECTRON_OZONE_PLATFORM_HINT= discord"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("uwsm app -- prime-run steam"))

-- -----------------------------------------------
-- Window Management
-- -----------------------------------------------

hl.bind(mainMod .. " + Q", hl.dsp.window.close()) -- Kill active window
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen()) -- Fullscreen
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" })) -- Toggle floating

-- Move focus (hjkl)
hl.bind(mainMod .. " + CTRL + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.focus({ direction = "down" }))

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true }) -- Move window
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- Resize window

-- Resize with keyboard
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = 50, y = 0, relative = true })) -- Increase width
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = -50, y = 0, relative = true })) -- Decrease width
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0, y = 50, relative = true })) -- Increase height
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0, y = -50, relative = true })) -- Decrease height

-- Groups
hl.bind(mainMod .. " + G", hl.dsp.group.toggle()) -- Toggle window group
hl.bind(mainMod .. " + CTRL + TAB", hl.dsp.group.next()) -- Change group active

-- Bring active to top
hl.bind(mainMod .. " + O", hl.dsp.window.alter_zorder({ mode = "top" }))

-- -----------------------------------------------
-- Actions (Quickshell, scripts)
-- -----------------------------------------------

hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/toggle-quickshell-power-menu.sh"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("sh -c 'hyprpicker -t -a'"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/toggle-quickshell-launcher.sh"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/toggle-quickshell-system-monitor.sh"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/toggle-quickshell-packages.sh"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/toggle-quickshell-clipboard.sh"))
hl.bind(
	mainMod .. " + SHIFT + S",
	hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/toggle-quickshell-screenshot-menu.sh")
)
hl.bind(mainMod .. " + SHIFT + CTRL + S", hl.dsp.exec_cmd("hyprshot -m region --output-folder ~/Pictures/"))
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/toggle-quickshell-wallpaper.sh"))
hl.bind(
	mainMod .. " + CTRL + SHIFT + W",
	hl.dsp.exec_cmd("sh -c 'killall quickshell 2>/dev/null || true; quickshell -p ~/dotfiles/.config/quickshell/ &'")
)
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-controlcenter.sh"))
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd("~/.config/hypr/scripts/run.sh"))

-- -----------------------------------------------
-- Workspaces
-- Switch with mainMod + [1-9, 0]
-- Move window with mainMod + SHIFT + [1-9, 0]
-- -----------------------------------------------

for i = 1, 10 do
	local key = i % 10 -- key 0 opens workspace 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Cycle workspaces
hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "m+1" })) -- Next workspace
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "m-1" })) -- Previous workspace

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Next empty workspace
hl.bind(mainMod .. " + CTRL + down", hl.dsp.focus({ workspace = "empty" }))

-- -----------------------------------------------
-- Session lock
-- -----------------------------------------------

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("/home/nabin/dotfiles/.config/quickshell/scripts/lock-session.sh"))
-- hl.bind("XF86Lock",             hl.dsp.exec_cmd("/home/nabin/dotfiles/.config/quickshell/scripts/lock-session.sh"), { locked = true })

-- -----------------------------------------------
-- Fn / Media Keys
-- -----------------------------------------------

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -q s +10%"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q s 10%-"), { locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true })

-- Keyboard backlight (raw keycodes for Apple/non-standard keyboards)
hl.bind("code:238", hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight s +10"))
hl.bind("code:237", hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight s 10-"))
