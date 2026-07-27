import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../shared"
import "components"

Scope {
  id: root

  required property var notificationServer
  required property var osd

  Theme { id: theme }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: bar
      required property var modelData

      screen: modelData

      implicitHeight: theme.barHeight
      exclusiveZone: theme.barHeight

      color: "transparent"

      anchors {
        top: true
        left: true
        right: true
      }

      AppLauncher {
        id: appLauncher
        parentWindow: bar
      }

      WallpaperLauncher {
        id: wallpaperLauncher
        parentWindow: bar
      }

      Item {
        anchors.fill: parent
        BarIsland {
          anchors.left: parent.left
          anchors.leftMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          implicitWidth: leftRow.implicitWidth + theme.islandPaddingH * 2

          Row {
            id: leftRow
            anchors.centerIn: parent
            spacing: theme.gap

            WorkspaceList {
              screen: bar.screen
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        BarIsland {
          anchors.centerIn: parent
          implicitWidth: centerRow.implicitWidth + theme.islandPaddingH * 2

          Row {
            id: centerRow
            anchors.centerIn: parent

            ClockWidget {}
          }
        }

        BarIsland {
          anchors.right: parent.right
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          implicitWidth: rightRow.implicitWidth + theme.islandPaddingH * 2

          Row {
            id: rightRow
            anchors.centerIn: parent
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

            BarIconButton {
              icon: "󰅇"
              active: clipboardLauncher.open
              anchors.verticalCenter: parent.verticalCenter
              onClicked: clipboardLauncher.open = !clipboardLauncher.open
            }

            // Control panel toggle
            SidebarButton {
              anchors.verticalCenter: parent.verticalCenter
              active: controlPanel.open
              onClicked: controlPanel.open = !controlPanel.open
            }
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
