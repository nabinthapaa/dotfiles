-- -----------------------------------------------
-- QT
-- -----------------------------------------------
-- For Qt apps you need: sudo pacman -S qt5ct qt6ct kvantum kvantum breeze-icons
-- You will need to set dark theme for qt apps from kde settings.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
