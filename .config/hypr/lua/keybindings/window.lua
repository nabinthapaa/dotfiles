local mainMod = "SUPER"

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

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true }) -- Move window
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- Resize window
