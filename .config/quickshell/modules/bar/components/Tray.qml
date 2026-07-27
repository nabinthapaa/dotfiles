// Tray.qml — System tray icons row.
import Quickshell.Services.SystemTray
import QtQuick
import "../../../shared"

Row {
  id: root

  required property var parentWindow

  spacing: 2
  visible: SystemTray.items.values.length > 0

  Theme { id: theme }

  Repeater {
    model: SystemTray.items

    Rectangle {
      id: trayItem

      required property var modelData

      width: theme.controlSize
      height: theme.controlSize
      radius: theme.radiusPill
      color: area.containsMouse ? theme.surfaceHigh : "transparent"

      Behavior on color {
        ColorAnimation { duration: 100 }
      }

      Image {
        anchors.centerIn: parent
        width: theme.iconSize
        height: theme.iconSize
        source: trayItem.modelData.icon
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
        smooth: true
      }

      MouseArea {
        id: area
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
          if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu) {
            const pos = trayItem.mapToItem(null, 0, trayItem.height);
            trayItem.modelData.display(root.parentWindow, pos.x, pos.y);
          } else if (mouse.button === Qt.MiddleButton) {
            trayItem.modelData.secondaryActivate();
          } else {
            trayItem.modelData.activate();
          }
        }
      }
    }
  }
}
