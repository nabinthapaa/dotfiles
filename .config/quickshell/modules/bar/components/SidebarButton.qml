import QtQuick
import "../../../shared"

Rectangle {
  id: root

  signal clicked()

  property bool active: false

  width: theme.controlSize
  height: theme.controlSize
  radius: theme.radiusLarge
  color: active ? theme.accentContainer : area.containsMouse ? theme.surfaceHover : theme.surface

  Theme {
    id: theme
  }

  Column {
    anchors.centerIn: parent
    spacing: 3

    Repeater {
      model: 3

      Rectangle {
        width: 13
        height: 2
        radius: 1
        color: root.active ? theme.accentContainerForeground : theme.foreground
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
