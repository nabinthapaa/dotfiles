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
      property alias isControlPanelOpen: controlPanel.open

      implicitHeight: Math.max(theme.barHeight, rightIsland.implicitHeight + 8)
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
          anchors.top: parent.top
          anchors.topMargin: (theme.barHeight - theme.islandHeight) / 2
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
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: (theme.barHeight - theme.islandHeight) / 2
          implicitWidth: root.osd.active ? 240 : centerRow.implicitWidth + theme.islandPaddingH * 2

          Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

          Item {
            anchors.fill: parent

            Row {
              id: centerRow
              anchors.centerIn: parent
              opacity: root.osd.active ? 0 : 1
              scale: root.osd.active ? 0.9 : 1
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

              ClockWidget {}
            }

            Row {
              id: osdRow
              anchors.fill: parent
              anchors.leftMargin: 16
              anchors.rightMargin: 16
              spacing: 12
              opacity: root.osd.active ? 1 : 0
              scale: root.osd.active ? 1 : 0.9
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.osd.icon
                color: theme.accent
                font.pixelSize: 16
              }

              Item {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 16 - 24 - 32 // Remaining width minus icon (16), 2x spacing (24), and text (32)
                height: 6

                Rectangle {
                  anchors.fill: parent
                  radius: 3
                  color: theme.surfaceHover

                  Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * root.osd.level
                    radius: 3
                    color: theme.accent
                    
                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                  }
                }
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                text: Math.round(root.osd.level * 100) + "%"
                color: theme.foreground
                font.pixelSize: 12
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignRight
              }
            }
          }
        }

        BarIsland {
          id: rightIsland
          anchors.right: parent.right
          anchors.rightMargin: 8
          anchors.top: parent.top
          anchors.topMargin: (theme.barHeight - theme.islandHeight) / 2
          
          implicitWidth: controlPanel.open ? 380 : rightRow.implicitWidth + theme.islandPaddingH * 2
          implicitHeight: controlPanel.open ? controlPanel.implicitHeight : theme.islandHeight

          customRadius: controlPanel.open ? theme.radiusLarge : theme.radiusPill
          Behavior on customRadius { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
          Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
          Behavior on implicitHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

          Item {
            anchors.fill: parent

            Row {
              id: rightRow
              anchors.centerIn: parent
              spacing: theme.gap
              opacity: controlPanel.open ? 0 : 1
              scale: controlPanel.open ? 0.9 : 1
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

              ConnectivityButtons { parentWindow: bar; anchors.verticalCenter: parent.verticalCenter }
              BatteryIndicator { anchors.verticalCenter: parent.verticalCenter }
              Tray { parentWindow: bar; anchors.verticalCenter: parent.verticalCenter }
              ClipboardLauncher { id: clipboardLauncher; parentWindow: bar; anchors.verticalCenter: parent.verticalCenter }
              BarIconButton { icon: "󰅇"; active: clipboardLauncher.open; anchors.verticalCenter: parent.verticalCenter; onClicked: clipboardLauncher.open = !clipboardLauncher.open }
              SidebarButton { anchors.verticalCenter: parent.verticalCenter; active: controlPanel.open; onClicked: controlPanel.open = !controlPanel.open }
            }

            ControlPanel {
              id: controlPanel
              anchors.centerIn: parent
              panelScreen: bar.screen
              notificationServer: root.notificationServer
              notificationCenter: root.notificationCenter
              osd: root.osd
              
              scale: controlPanel.open ? 1 : 0.95
              opacity: controlPanel.open ? 1 : 0
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
            }
          }
        }
      }

      PopupWindow {
        parentWindow: bar
        relativeX: 0
        relativeY: 0
        width: bar.screen.width
        height: bar.screen.height
        visible: controlPanel.open
        color: "#01000000"
        
        MouseArea {
          anchors.fill: parent
          onClicked: controlPanel.open = false
        }
      }
    }
  }
}
