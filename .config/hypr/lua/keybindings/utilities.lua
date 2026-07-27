local mainMod = "SUPER"

-- -----------------------------------------------
-- Utilities (Screenshot, Color Picker, Gamepad)
-- -----------------------------------------------

hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("sh -c 'hyprpicker -t -a'"))
hl.bind(mainMod .. " + SHIFT + CTRL + S", hl.dsp.exec_cmd("hyprshot -m region --output-folder ~/Pictures/"))
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd("~/.config/hypr/scripts/runner.lua gamepad"))
