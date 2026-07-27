-- -----------------------------------------------
-- Mozilla / Electron / Ozone
-- -----------------------------------------------
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("WAYLAND_DISPLAY", "wayland-1")
