import Quickshell.Services.SystemTray
import QtQuick
import "../../../shared"

Row {
  id: root

  required property var parentWindow

  spacing: theme.gap / 2
  visible: SystemTray.items.values.length > 0

  Theme {
    id: theme
  }

  Repeater {
    model: SystemTray.items

    Item {
      id: trayItem

      required property var modelData

      width: theme.controlSize
      height: theme.controlSize

      Rectangle {
        anchors.fill: parent
        radius: theme.radiusLarge
        color: area.containsMouse ? theme.surfaceHover : "transparent"
      }

      Image {
        anchors.centerIn: parent
        width: theme.iconSize
        height: theme.iconSize
        source: trayItem.modelData.icon
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
      }

      MouseArea {
        id: area
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
          if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu) {
            const position = trayItem.mapToItem(null, 0, trayItem.height);
            trayItem.modelData.display(root.parentWindow, position.x, position.y);
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
