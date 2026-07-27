// BarIconButton.qml — Compact icon-only button for the bar.
import QtQuick
import "../../../shared"

Rectangle {
  id: root

  signal clicked()

  property string icon: ""
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

  Text {
    anchors.centerIn: parent
    text: root.icon
    font.pixelSize: 14
    font.family: "Symbols Nerd Font"
    color: root.active ? theme.accentContainerForeground : theme.foreground

    Behavior on color {
      ColorAnimation { duration: 120 }
    }
  }

  Behavior on color {
    ColorAnimation { duration: 120 }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
