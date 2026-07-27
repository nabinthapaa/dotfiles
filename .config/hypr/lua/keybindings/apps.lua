local mainMod = "SUPER"

-- -----------------------------------------------
-- Applications
-- -----------------------------------------------

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("uwsm app -- ghostty")) -- Open terminal
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("uwsm app -- zen-browser")) -- Open browser
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("uwsm app -- thunar")) -- Open file manager
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("uwsm app -- env ELECTRON_OZONE_PLATFORM_HINT= discord"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("uwsm app -- prime-run steam"))
