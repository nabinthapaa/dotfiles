// ClockWidget.qml — Single-line compact clock for the center island.
// Shows HH:mm in bold and short date in muted color side-by-side.
import Quickshell
import Quickshell.Io
import QtQuick
import "../../../shared"

Item {
  id: root
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  Theme { id: theme }

  property string nepaliDateText: ""

  Row {
    id: row
    spacing: 6

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Process {
    id: nepaliDateCommand
    command: ["sh", "-c", "$HOME/dotfiles/.config/quickshell/scripts/nepali-date.sh"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        root.nepaliDateText = text.trim();
      }
    }
  }

  Timer {
    interval: 3600000 // 1 hour
    running: true
    repeat: true
    onTriggered: {
      nepaliDateCommand.running = false;
      nepaliDateCommand.running = true;
    }
  }

  // 1. Left: Nepali Date
  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: root.nepaliDateText
    color: theme.muted
    font.pixelSize: 11
    font.weight: Font.Medium
    visible: root.nepaliDateText.length > 0
  }

  // Subtle separator for Nepali Date
  Rectangle {
    width: 1
    height: 14
    anchors.verticalCenter: parent.verticalCenter
    color: Qt.rgba(theme.border.r, theme.border.g, theme.border.b, 0.6)
    visible: root.nepaliDateText.length > 0
  }

  // 2. Center: Time
  Text {
    anchors.verticalCenter: parent.verticalCenter
    text: Qt.formatDateTime(clock.date, "HH:mm")
    color: theme.foreground
    font.pixelSize: 13
    font.weight: Font.DemiBold
    font.letterSpacing: 0.4
  }

  // Subtle separator for English Date
  Rectangle {
    width: 1
    height: 14
    anchors.verticalCenter: parent.verticalCenter
    color: Qt.rgba(theme.border.r, theme.border.g, theme.border.b, 0.6)
  }

    // 3. Right: English Date
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Qt.formatDateTime(clock.date, "ddd, d MMM")
      color: theme.muted
      font.pixelSize: 11
      font.weight: Font.Medium
    }
  }
}
