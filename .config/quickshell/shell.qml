//@ pragma UseQApplication

import Quickshell
import "modules/bar"
import "modules/notifications"
import "modules/osd"
import "modules/power"
import "modules/screenshot"

ShellRoot {
  Osd {
    id: osd
  }

  NotificationCenter {
    id: notifications
  }

  PowerMenu {}

  ScreenshotMenu {}

  TopBar {
    notificationServer: notifications.server
    osd: osd
  }
}
