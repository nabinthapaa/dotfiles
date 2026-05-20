# Quickshell config

Named Quickshell config for Hyprland. This config targets Quickshell `0.3`
and keeps each shell area in its own module.

## Run

```sh
qs -p ~/dotfiles/.config/quickshell/shell.qml
```

Quickshell treats every folder under `$XDG_CONFIG_HOME/quickshell` that
contains `shell.qml` as a named config.

## Layout

```text
.config/quickshell/
  shell.qml                         # entrypoint
  shared/Theme.qml                  # shared colors, sizes, spacing
  theme/Matugen.qml                 # generated Material color roles
  modules/notifications/
    NotificationCenter.qml          # notification daemon and toast popups
  modules/osd/
    Osd.qml                         # bottom-center status overlay
  modules/power/
    PowerMenu.qml                   # fullscreen lock/logout menu
  modules/screenshot/
    ScreenshotMenu.qml              # screenshot type selector
  modules/bar/TopBar.qml            # one top bar per screen
  modules/bar/components/
    AppLauncher.qml                 # Material application launcher
    WallpaperLauncher.qml           # wallpaper picker with preview
    WorkspaceList.qml               # Hyprland workspace buttons
    ClockWidget.qml                 # centered time and date
    ConnectivityButtons.qml         # Wi-Fi and Bluetooth bar buttons
    BatteryIndicator.qml            # laptop battery status
    Tray.qml                        # system tray icons
    SidebarButton.qml               # future control panel trigger
    ControlPanel.qml                # full-height right-side sliding panel
  scripts/
    apply-wallpaper.sh              # applies selected wallpaper from Quickshell
    take-screenshot.sh              # captures selected screenshot type
```

## Current Bar

- Left: numbered Hyprland workspaces `1` through `10`.
- Center: time on top, date below it.
- Right: Wi-Fi and Bluetooth status buttons, laptop battery when present,
  system tray icons, then the sidebar button.
- Sidebar button opens a full-height right-side control panel overlay.

`TopBar.qml` uses `Variants { model: Quickshell.screens }`, so each connected
screen gets its own `PanelWindow`. The window is anchored to the top, left, and
right edges and reserves `Theme.barHeight` pixels using `exclusiveZone`.

## Editing Notes

- Change bar height, gaps, icon size, and radius in `shared/Theme.qml`.
- Generated Material colors come from `theme/Matugen.qml`; `shared/Theme.qml`
  maps those roles to shell-level names like `background`, `surface`, `accent`,
  and `foreground`.
- Component styling follows Material role usage: layered surfaces use
  `surfaceContainer*`, selected controls use `primaryContainer`, outlines use
  `outlineVariant`, and primary slider fill uses `primary`.
- Add new bar widgets under `modules/bar/components/`.
- Move the control panel to `modules/control-panel/` if it grows beyond a few
  compact controls.
- Avoid `root:/...` imports. The official guide warns that those old imports
  can break LSP and singletons. Use relative imports like this config does.

## Workspace Notes

`WorkspaceList.qml` uses `Quickshell.Hyprland`:

- `Hyprland.workspaces.values` reads known workspaces.
- `Hyprland.monitorFor(screen)` maps the Quickshell screen to a Hyprland
  monitor.
- `Hyprland.dispatch("workspace " + id)` switches workspace on click.

This first version shows fixed workspaces `1` through `10`. Named or special
workspaces can be added later by changing the repeater model.

## Application Launcher Notes

`AppLauncher.qml` uses `Quickshell.DesktopEntries`:

- It is hidden from the top bar and opens through IPC/keybinding.
- Search filters by application name, generic name, comment, keywords, and
  categories.
- Clicking an app or pressing Enter on a search result calls
  `DesktopEntry.execute()`.
- Clicking outside closes the popup through `PopupWindow.grabFocus`.
- Each screen gets an IPC target named `appLauncher.<screen>`.

Useful launcher IPC commands:

```sh
qs ipc call appLauncher.eDP-1 open
qs ipc call appLauncher.eDP-1 close
qs ipc call appLauncher.eDP-1 toggle
qs ipc call appLauncher.eDP-1 isOpen
```

When this config is launched by path, use the same path selector for IPC:

```sh
qs -p ~/dotfiles/.config/quickshell ipc call appLauncher.eDP-1 toggle
```

The Hyprland `SUPER+SPACE` bind uses
`~/dotfiles/.config/hypr/scripts/toggle-quickshell-launcher.sh`, which resolves
the focused Hyprland monitor and calls the matching `appLauncher.<monitor>`
target with the `-p` selector.

## Wallpaper Launcher Notes

`WallpaperLauncher.qml` is hidden from the top bar and opens through IPC. It
uses the same centered popup pattern as the app launcher:

- Search is at the top.
- Selected wallpaper preview is on the left.
- Wallpaper options are listed on the right.
- `Ctrl+N` moves down, `Ctrl+P` moves up, and selection wraps.
- Enter or click applies the selected wallpaper.

Wallpaper files are loaded from `~/wallpaper`. Applying a wallpaper mirrors the
Hyprland wallpaper script: it updates Hyprpaper on all monitors, writes the
current wallpaper cache, runs `wal` and Matugen when available, regenerates
lockscreen/cache images with ImageMagick when available, updates
`~/.config/hypr/hyprpaper.conf`, and reloads Hyprland. The actual apply command
is kept in `scripts/apply-wallpaper.sh` so failures can notify clearly and
non-critical steps do not stop the wallpaper change.

Useful wallpaper IPC commands:

```sh
qs -p ~/dotfiles/.config/quickshell ipc call wallpaperLauncher.eDP-1 open
qs -p ~/dotfiles/.config/quickshell ipc call wallpaperLauncher.eDP-1 close
qs -p ~/dotfiles/.config/quickshell ipc call wallpaperLauncher.eDP-1 toggle
qs -p ~/dotfiles/.config/quickshell ipc call wallpaperLauncher.eDP-1 isOpen
```

## Power Menu Notes

`PowerMenu.qml` replaces the rofi power menu with a fullscreen selector. It uses
the blurred wallpaper cache at `~/.cache/wal/blurred_wallpaper.png` as the
background and places the six actions in a centered grid:

- Lock
- Exit
- Hibernate
- Suspend
- Reboot
- Shutdown

Keyboard behavior:

- `Tab` selects the next action.
- `Shift+Tab` selects the previous action.
- Arrow keys also move selection.
- Enter runs the selected action.
- Escape or clicking the backdrop closes the menu.

Each screen gets an IPC target named `powerMenu.<screen>`. The Hyprland
`SUPER+L` bind uses `~/dotfiles/.config/hypr/scripts/toggle-quickshell-power-menu.sh`,
which resolves the focused Hyprland monitor and toggles the matching IPC target.

## Screenshot Selector Notes

`ScreenshotMenu.qml` replaces the rofi screenshot type selector for the control
panel action. The selector opens as a small fullscreen overlay with three modes:

- Full Screen
- Selected Area
- Active Window

Keyboard behavior matches the other selectors: `Tab` and arrow keys cycle,
Enter runs the selected mode, and Escape closes. Captures are handled by
`scripts/take-screenshot.sh`, which uses `hyprshot`, saves to
`~/Pictures/Screenshots`, copies the image to the clipboard when `wl-copy` is
available, and sends a notification.

## Tray Notes

`Tray.qml` uses `Quickshell.Services.SystemTray`:

- `SystemTray.items` provides tray entries.
- `item.icon` is used as the image source.
- Left click calls `activate()`.
- Middle click calls `secondaryActivate()`.
- Right click calls `display(parentWindow, x, y)` when a menu exists.

## Connectivity Notes

`ConnectivityButtons.qml` sits immediately before the tray:

- Wi-Fi shows the connected SSID, or `Not connected`.
- Bluetooth shows connected device names, or `Not connected`.
- Clicking Wi-Fi opens a compact `PopupWindow` below the bar.
- Clicking Bluetooth opens a matching compact `PopupWindow` below the bar.
- While the Wi-Fi popup is open, `WifiDevice.scannerEnabled` is enabled so the
  available networks list stays populated.
- Saved and open networks call `Network.connect()`.
- Unsaved PSK networks open an inline password prompt and use
  `WifiNetwork.connectWithPsk(password)`.
- If connection fails because secrets are missing or wrong, the password prompt
  is shown again inside the same popup.
- The Bluetooth popup has an adapter power toggle in the header.
- Known Bluetooth devices are listed from the default adapter and filtered to
  paired, bonded, trusted, or connected devices.
- Clicking a known Bluetooth device connects it, or disconnects it when already
  connected.

## Battery Notes

`BatteryIndicator.qml` uses `Quickshell.Services.UPower`:

- It is hidden when no laptop battery is exposed by UPower.
- It shows the battery percentage from the laptop battery device.
- The icon changes by charge level.
- Charging and pending-charge states use the charging icon.
- Low battery on discharge uses the warning color.

## Control Panel Notes

`ControlPanel.qml` uses `PanelWindow`:

- `open` controls visibility.
- A transparent full-screen click target closes it when clicking outside the panel.
- `Keys.onEscapePressed` closes it on Escape while focused.
- It is anchored to all screen edges and draws the panel below the top bar,
  extending to the bottom of the screen.
- The window stays visible during the close animation so it slides out cleanly.
- The body has two pages. Quick controls are the default page. The header power
  button toggles the power page, and each incoming page slides in from the right.
- Below the quick controls, a two-tab section defaults to Notifications and
  switches between Notifications and Controls content.
- The Notifications tab has a scrollable notification list backed by
  `NotificationServer.trackedNotifications`, with an MPRIS media card below it.
- `NotificationCenter.qml` owns the single notification daemon and toast UI.
  Control panels consume that shared server instead of creating one per screen.
- Toasts and panel notifications render action buttons from
  `Notification.actions`; clicking one calls `NotificationAction.invoke()`.
- Notification app icons resolve through `Quickshell.iconPath()` with
  `desktopEntry` as a fallback.
- The MPRIS card is a carousel: one player at a time, previous/next player
  buttons when multiple players exist, plus dots for the current player.
- The Controls tab contains mic and audio sliders backed by Quickshell
  PipeWire default source/sink volume, and a brightness slider backed by
  `brightnessctl`.
- Each screen gets an IPC target named `controlPanel.<screen>`, for example
  `controlPanel.eDP-1`.

Useful IPC commands:

```sh
qs ipc show
qs ipc call controlPanel.eDP-1 open
qs ipc call controlPanel.eDP-1 close
qs ipc call controlPanel.eDP-1 toggle
qs ipc call controlPanel.eDP-1 isOpen
qs ipc call controlPanel.eDP-1 screen
```
- Wi-Fi uses `Quickshell.Networking` to show the connected network name, or
  `Not connected`. The tile accent follows `Networking.wifiEnabled`.
- Bluetooth uses `Quickshell.Bluetooth` to show connected default-adapter device
  names, or `Not connected`. The tile accent follows the default adapter enabled
  state.
- Night Light uses `hyprsunset`: enabling runs `hyprctl hyprsunset temperature
  4500` and falls back to `hyprsunset -t 4500`; disabling runs `hyprctl
  hyprsunset identity`.
- Do Not Disturb is a local toggle for now and shows `On` or `Off`.

## OSD Notes

`modules/osd/Osd.qml` draws a small bottom-center overlay above all windows.
It is intentionally independent from the top bar so any module can call it.

Current OSD events:

- Volume and mute state.
- Microphone level and mute state.
- Brightness level.
- Power profile changes.
- Airplane mode state.
- Silent mode state.

Useful OSD IPC commands:

```sh
qs ipc call osd volume 0.7 false
qs ipc call osd mic 0.4 true
qs ipc call osd brightness 0.8
qs ipc call osd powerProfile performance
qs ipc call osd powerProfile balanced
qs ipc call osd powerProfile power-saver
qs ipc call osd airplane true
qs ipc call osd silent true
```

The control panel already calls the OSD from the audio, mic, brightness,
Wi-Fi, and Do Not Disturb controls. Power profile support uses
`Quickshell.Services.UPower.PowerProfiles`; the power profiles daemon must be
installed for changing system profiles to work.

External changes are watched too:

- PipeWire default sink changes show the volume OSD, including mute/unmute.
- PipeWire default source changes show the microphone OSD, including mute/unmute.
- `brightnessctl -m` is polled so hardware brightness keys show the brightness
  OSD after the value changes.
- UPower power profile changes show the power mode OSD.

Hyprland keybinds only need to change the system value, for example through
`wpctl`, `pamixer`, or `brightnessctl`. They do not need to call `qs ipc` unless
you want to show a custom OSD event.

## Official Docs Used

- Quickshell introduction and config paths:
  https://quickshell.org/docs/v0.3.0/guide/introduction/
- `PanelWindow`:
  https://quickshell.org/docs/v0.3.0/types/Quickshell/PanelWindow/
- `Quickshell.screens`:
  https://quickshell.org/docs/v0.3.0/types/Quickshell/Quickshell/
- Hyprland integration:
  https://quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/Hyprland/
- Hyprland workspace:
  https://quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/HyprlandWorkspace/
- System tray:
  https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.SystemTray/SystemTray/
- System tray item:
  https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.SystemTray/SystemTrayItem/
- Popup window:
  https://quickshell.org/docs/v0.3.0/types/Quickshell/PopupWindow/
- Desktop entries:
  https://quickshell.org/docs/types/Quickshell/DesktopEntries/
- Desktop entry:
  https://quickshell.org/docs/types/Quickshell/DesktopEntry/
- Networking:
  https://quickshell.org/docs/v0.3.0/types/Quickshell.Networking/Networking/
- Network:
  https://quickshell.org/docs/v0.3.0/types/Quickshell.Networking/Network/
- Wi-Fi device:
  https://quickshell.org/docs/v0.3.0/types/Quickshell.Networking/WifiDevice/
- Wi-Fi network:
  https://quickshell.org/docs/v0.3.0/types/Quickshell.Networking/WifiNetwork/
- Notification server:
  https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Notifications/NotificationServer/
- MPRIS:
  https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Mpris/Mpris/
- PipeWire:
  https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Pipewire/Pipewire/
- UPower power profiles:
  https://quickshell.org/docs/types/Quickshell.Services.UPower/PowerProfiles/
- UPower battery service:
  https://quickshell.org/docs/types/Quickshell.Services.UPower/UPower/
- IPC handler:
  https://quickshell.org/docs/v0.3.0/types/Quickshell.Io/IpcHandler/
