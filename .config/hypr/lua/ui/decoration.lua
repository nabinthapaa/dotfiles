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
