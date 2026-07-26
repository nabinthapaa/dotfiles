-- -----------------------------------------------
-- Monitors
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- -----------------------------------------------

hl.monitor({
	output = "",
	mode = "2560x1600@165",
	position = "auto",
	scale = 1.067,
})

hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@200",
	position = "auto",
	scale = 1,
})

-- -----------------------------------------------
-- General
-- -----------------------------------------------

hl.config({
	general = {
		gaps_in = 1,
		gaps_out = 1,
		border_size = 1,
		col = {
			inactive_border = "rgba(4B463966)",
			active_border = "rgba(DEC56EFF)",
		},
		layout = "dwindle",
		resize_on_border = true,
	},
})

-- -----------------------------------------------
-- Cursor
-- -----------------------------------------------

hl.config({
	cursor = {
		no_hardware_cursors = true,
	},
})

-- -----------------------------------------------
-- Input
-- -----------------------------------------------

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		numlock_by_default = false,
		follow_mouse = 1,
		mouse_refocus = false,
		touchpad = {
			natural_scroll = false,
			scroll_factor = 1.0,
			middle_button_emulation = true,
			clickfinger_behavior = true,
		},
		sensitivity = 0, -- Pointer speed: -1.0 - 1.0, 0 means no modification.
	},
})

-- -----------------------------------------------
-- Decoration
-- -----------------------------------------------

hl.config({
	decoration = {
		rounding = 5,
		active_opacity = 1.0,
		inactive_opacity = 0.99,
		fullscreen_opacity = 1.0,
		blur = {
			enabled = true,
			size = 8,
			passes = 3,
			new_optimizations = true,
			ignore_opacity = false,
			xray = false,
		},
	},
})

-- -----------------------------------------------
-- Animations
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
-- -----------------------------------------------

hl.config({
	animations = {
		enabled = true,
	},
})

hl.curve("wind", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.4, 0 }, { 1, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "winOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner", style = "once" })
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "wind", style = "slide" })

-- -----------------------------------------------
-- Dwindle layout
-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
-- -----------------------------------------------

-- hl.config({
-- 	dwindle = {
-- 		pseudotile = true,
-- 		preserve_split = true,
-- 	},
-- })

-- -----------------------------------------------
-- Gestures
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- -----------------------------------------------

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down", mods = "ALT", action = "close" })
hl.gesture({ fingers = 3, direction = "up", mods = "SHIFT", action = "float" })
hl.gesture({ fingers = 3, direction = "left", mods = "SHIFT", action = "resize" })
hl.gesture({ fingers = 3, direction = "up", mods = "SUPER", scale = 1.5, action = "fullscreen" })

-- -----------------------------------------------
-- Binds (workspace_back_and_forth etc.)
-- -----------------------------------------------

hl.config({
	binds = {
		workspace_back_and_forth = false,
		allow_workspace_cycles = true,
		pass_mouse_when_bound = false,
	},
})
