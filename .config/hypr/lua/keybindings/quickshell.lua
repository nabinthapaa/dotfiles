local mainMod = "SUPER"

-- -----------------------------------------------
-- Quickshell & Menus
-- -----------------------------------------------

hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/runner.lua qs-launcher"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/runner.lua qs-system"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/runner.lua qs-packages"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/runner.lua qs-clipboard"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/runner.lua qs-power"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/runner.lua qs-screenshot"))
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/runner.lua qs-wallpaper"))
hl.bind(mainMod .. " + CTRL + SHIFT + W", hl.dsp.exec_cmd("sh -c 'quickshell -n -p ~/dotfiles/.config/quickshell/ &'"))

hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("~/dotfiles/.config/hypr/scripts/runner.lua qs-control-center"))
