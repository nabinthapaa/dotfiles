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
