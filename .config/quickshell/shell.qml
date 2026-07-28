//@ pragma UseQApplication

import Quickshell
import "modules/bar"
import "modules/notifications"
import "modules/lockscreen"
import "modules/packages"
import "modules/osd"
import "modules/power"
import "modules/screenshot"
import "modules/system"
import "modules/overview"
import "shared"

ShellRoot {
  BrightnessTracker { id: brightnessTracker }

  Osd {
    id: osd
    brightnessTracker: brightnessTracker
  }

  NotificationCenter {
    id: notifications
  }

  LockScreen {
    notificationServer: notifications.server
  }

  PowerMenu {}



  ScreenshotMenu {}

  SystemMonitor {}

  TopBar {
    notificationServer: notifications.server
    property var notificationCenter: notifications
    osd: osd
    brightnessTracker: brightnessTracker
  }
}
