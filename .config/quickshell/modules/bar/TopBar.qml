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
      property alias isWifiOpen: connectivityBtns.wifiPopupOpen
      property alias isBtOpen: connectivityBtns.bluetoothPopupOpen
      property bool isAnyPanelOpen: isControlPanelOpen || isWifiOpen || isBtOpen

      implicitHeight: screen.height
      exclusiveZone: theme.barHeight

      color: "transparent"

      mask: Region {
        Region { item: leftIsland }
        Region { item: centerIsland }
        Region { item: rightIsland }
        Region { item: notificationsIsland }
      }

      HyprlandFocusGrab {
        active: bar.isAnyPanelOpen
        windows: [ bar ]
        onCleared: {
          bar.isControlPanelOpen = false;
          bar.isWifiOpen = false;
          bar.isBtOpen = false;
        }
      }

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
          id: leftIsland
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
          id: centerIsland
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
          
          implicitWidth: bar.isControlPanelOpen ? 380 :
                         bar.isWifiOpen ? 336 :
                         bar.isBtOpen ? 320 :
                         rightRow.implicitWidth + theme.islandPaddingH * 2
          
          implicitHeight: bar.isControlPanelOpen ? controlPanel.implicitHeight :
                          bar.isWifiOpen ? 384 :
                          bar.isBtOpen ? 340 :
                          theme.islandHeight

          customRadius: bar.isAnyPanelOpen ? theme.radiusLarge : theme.radiusPill
          Behavior on customRadius { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
          Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
          Behavior on implicitHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

          Item {
            anchors.fill: parent

            Row {
              id: rightRow
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              anchors.topMargin: (theme.islandHeight - implicitHeight) / 2
              spacing: theme.gap
              opacity: bar.isAnyPanelOpen ? 0 : 1
              scale: bar.isAnyPanelOpen ? 0.9 : 1
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

              ConnectivityButtons { id: connectivityBtns; parentWindow: bar; island: rightIsland; anchors.verticalCenter: parent.verticalCenter }
              BatteryIndicator { anchors.verticalCenter: parent.verticalCenter }
              Tray { parentWindow: bar; anchors.verticalCenter: parent.verticalCenter }
              ClipboardLauncher { id: clipboardLauncher; parentWindow: bar; anchors.verticalCenter: parent.verticalCenter }
              BarIconButton { icon: "󰅇"; active: clipboardLauncher.open; anchors.verticalCenter: parent.verticalCenter; onClicked: clipboardLauncher.open = !clipboardLauncher.open }
              SidebarButton { anchors.verticalCenter: parent.verticalCenter; active: controlPanel.open; onClicked: controlPanel.open = !controlPanel.open }
            }

            ControlPanel {
              id: controlPanel
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
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

        BarIsland {
          id: notificationsIsland
          anchors.right: parent.right
          anchors.rightMargin: 8
          anchors.top: rightIsland.bottom
          anchors.topMargin: theme.gap
          
          implicitWidth: rightIsland.width
          implicitHeight: bar.isControlPanelOpen ? 360 : 0
          customRadius: theme.radiusLarge
          
          opacity: bar.isControlPanelOpen ? 1 : 0
          scale: bar.isControlPanelOpen ? 1 : 0.95
          visible: opacity > 0
          
          Behavior on implicitHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
          Behavior on opacity { NumberAnimation { duration: 150 } }
          Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
          
          Item {
            anchors.fill: parent
            anchors.margins: 16
            
            NotificationPanel {
              anchors.fill: parent
              notificationServer: root.notificationServer
              notificationCenter: root.notificationCenter
            }
          }
        }
      }
    }
  }
}
