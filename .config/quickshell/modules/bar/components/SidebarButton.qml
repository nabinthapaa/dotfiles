// SidebarButton.qml — Hamburger/menu button that opens the control panel.
import QtQuick
import "../../../shared"

Rectangle {
  id: root

  signal clicked()

  property bool active: false

  width: theme.controlSize
  height: theme.controlSize
  radius: theme.radiusPill
  color: active
    ? theme.accentContainer
    : area.containsMouse
      ? theme.surfaceHover
      : "transparent"

  Theme { id: theme }

  Behavior on color {
    ColorAnimation { duration: 120 }
  }

  // Three-line hamburger icon
  Column {
    anchors.centerIn: parent
    spacing: 4

    Repeater {
      model: 3

      Rectangle {
        // Middle line is shorter for aesthetic
        width: index === 1 ? 10 : 14
        height: 2
        radius: 1
        color: root.active ? theme.accentContainerForeground : theme.foreground

        Behavior on color {
          ColorAnimation { duration: 120 }
        }
      }
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
