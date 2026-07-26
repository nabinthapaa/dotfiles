-- -----------------------------------------------
-- Environment Variables
-- -----------------------------------------------

-- NVIDIA https://wiki.hyprland.org/Nvidia/
-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("GBM_BACKEND", "nvidia-drm")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("NVD_BACKEND", "direct")
-- hl.env("MOZ_X11_EGL", "1")
-- hl.env("MOZ_DISABLE_RDD_SANDBOX", "1")
-- hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/10_nvidia.json")
-- hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
-- hl.env("SDL_VIDEODRIVER", "wayland")

-- XDG Desktop Portal
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- QT
-- For Qt apps you need: sudo pacman -S qt5ct qt6ct kvantum kvantum breeze-icons
-- You will need to set dark theme for qt apps from kde settings.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

-- GDK
hl.env("GDK_SCALE", "1")

-- Toolkit Backend
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")

-- Mozilla / Electron / Ozone
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("WAYLAND_DISPLAY", "wayland-1")

-- Cursor
hl.env("XCURSOR_SIZE", "24")

-- Disable AppImage launcher by default
hl.env("APPIMAGELAUNCHER_DISABLE", "1")
