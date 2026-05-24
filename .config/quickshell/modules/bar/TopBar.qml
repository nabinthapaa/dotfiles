import Quickshell
import QtQuick
import "../../shared"
import "components"

Scope {
  id: root

  required property var notificationServer
  required property var osd

  Theme {
    id: theme
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: bar
      required property var modelData

      screen: modelData
      implicitHeight: theme.barHeight
      color: theme.background
      exclusiveZone: theme.barHeight

      anchors {
        top: true
        left: true
        right: true
      }

      Item {
        anchors.fill: parent
        anchors.leftMargin: theme.barPadding
        anchors.rightMargin: theme.barPadding

        Row {
          id: leftGroup

          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: theme.gap

          AppLauncher {
            parentWindow: bar
            anchors.verticalCenter: parent.verticalCenter
          }

          WallpaperLauncher {
            parentWindow: bar
            anchors.verticalCenter: parent.verticalCenter
          }

          WorkspaceList {
            id: workspaces
            screen: bar.screen
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        ClockWidget {
          anchors.centerIn: parent
        }

        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: theme.gap

          ConnectivityButtons {
            parentWindow: bar
            anchors.verticalCenter: parent.verticalCenter
          }

          BatteryIndicator {
            anchors.verticalCenter: parent.verticalCenter
          }

          Tray {
            parentWindow: bar
            anchors.verticalCenter: parent.verticalCenter
          }

          ClipboardLauncher {
            id: clipboardLauncher
            parentWindow: bar
            anchors.verticalCenter: parent.verticalCenter
          }

          Rectangle {
            width: theme.controlSize
            height: theme.controlSize
            radius: theme.radiusLarge
            color: clipboardLauncher.open ? theme.accentContainer : clipboardArea.containsMouse ? theme.surfaceHover : theme.surface

            Text {
              anchors.centerIn: parent
              text: "󰅇"
              color: clipboardLauncher.open ? theme.accentContainerForeground : theme.foreground
              font.pixelSize: 15
            }

            MouseArea {
              id: clipboardArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: clipboardLauncher.open = !clipboardLauncher.open
            }
          }

          SidebarButton {
            anchors.verticalCenter: parent.verticalCenter
            active: controlPanel.open
            onClicked: controlPanel.open = !controlPanel.open
          }
        }
      }

      ControlPanel {
        id: controlPanel
        panelScreen: bar.screen
        notificationServer: root.notificationServer
        osd: root.osd
      }
    }
  }
}
