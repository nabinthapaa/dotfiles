import Quickshell
import QtQuick
import "../../../shared"

Column {
  id: root

  spacing: 1

  Theme {
    id: theme
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: Qt.formatDateTime(clock.date, "HH:mm")
    color: theme.foreground
    font.pixelSize: 15
    font.weight: Font.DemiBold
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    text: Qt.formatDateTime(clock.date, "ddd, MMM d")
    color: theme.muted
    font.pixelSize: 11
    font.weight: Font.Medium
  }
}
