-- -----------------------------------------------
-- Window Rules
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- -----------------------------------------------

-- Picture-in-Picture: float, pin, and position in the corner
hl.window_rule({
	name = "pip-float-pin",
	match = { title = "^(Picture-in-Picture)$" },
	float = true,
	pin = true,
	move = "69.5% 4%",
})

-- nm-connection-editor: float
hl.window_rule({
	name = "nm-connection-editor-float",
	match = { class = "^(nm-connection-editor)$" },
	float = true,
})

-- Wifi-tauri: float
hl.window_rule({
	name = "wifi-tauri-float",
	match = { class = "^(Wifi-tauri)$" },
	float = true,
})

-- com.example.wayfi: float
hl.window_rule({
	name = "wayfi-float",
	match = { class = "^(com.example.wayfi)$" },
	float = true,
})

-- nmtui in kitty
hl.window_rule({
	name = "Float nmtui kitty",
	match = { class = "^(kitty)$", title = "^(nmtui)$" },
	size = "1000 1000",
	float = true,
	center = true,
	animation = "popin",
})

-- btop in kitty
hl.window_rule({
	name = "Float btop kitty",
	match = { class = "^(kitty)$", title = "^(btop)$" },
	size = "1000 1000",
	float = true,
	center = true,
	animation = "popin",
})

-- PulseAudio Volume Control
hl.window_rule({
	name = "Float pavucontrol",
	match = { class = ".*org.pulseaudio.pavucontrol.*" },
	size = "1000 1000",
	float = true,
	center = true,
	animation = "popin",
})

-- Blueman Bluetooth Manager
hl.window_rule({
	name = "Float blueman-manager",
	match = { class = "^(blueman-manager)$" },
	size = "1000 1000",
	float = true,
	center = true,
	animation = "popin",
})

-- KDE System Settings
hl.window_rule({
	name = "Float settings",
	match = { title = "^(System Settings)$" },
	size = "1000 1000",
	float = true,
	center = true,
	animation = "popin",
})

-- Quickshell Control Center
hl.window_rule({
	name = "Control Center",
	match = { title = "^(quickshell-controlcenter)$" },
	move = "onscreen 100%-w-20 50%",
	float = true,
	pin = true,
})

-- Quickshell Bar (tiled)
hl.window_rule({
	name = "Quickshell Bar",
	match = { title = "^(quickshell-bar)$" },
	float = false,
})

-- Transmission
hl.window_rule({
	name = "Transmission",
	match = { class = "^(com.transmissionbt.transmission_49_12356179)$" },
	float = true,
	size = "1000 1000",
	center = true,
	animation = "popin",
})
