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

ShellRoot {
  Osd {
    id: osd
  }

  NotificationCenter {
    id: notifications
  }

  LockScreen {
    notificationServer: notifications.server
  }

  PowerMenu {}

  PackageSearcher {}

  ScreenshotMenu {}

  SystemMonitor {}

  TopBar {
    notificationServer: notifications.server
    osd: osd
  }
}
