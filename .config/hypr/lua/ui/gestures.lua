-- -----------------------------------------------
-- Gestures
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- -----------------------------------------------

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down", mods = "ALT", action = "close" })
hl.gesture({ fingers = 3, direction = "up", mods = "SHIFT", action = "float" })
hl.gesture({ fingers = 3, direction = "left", mods = "SHIFT", action = "resize" })
hl.gesture({ fingers = 3, direction = "up", mods = "SUPER", scale = 1.5, action = "fullscreen" })
