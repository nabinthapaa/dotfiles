local mainMod = "SUPER"

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
