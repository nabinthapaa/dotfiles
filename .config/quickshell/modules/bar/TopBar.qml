import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import QtQuick
import "../../shared"
import "../calendar"
import "../packages"
import "../overview" as OverviewModule
import "components"

Scope {
  id: root

  required property var notificationServer
  required property var osd
  required property var brightnessTracker
  required property var polkitAgent

  property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
  property string lastTrackTitle: activePlayer ? activePlayer.trackTitle : ""
  property int lastPlaybackState: activePlayer ? activePlayer.playbackState : 0
  property bool mediaPopupActive: false

  onLastTrackTitleChanged: triggerMediaPopup()
  onLastPlaybackStateChanged: triggerMediaPopup()

  function triggerMediaPopup() {
    if (activePlayer && activePlayer.trackTitle.length > 0) {
      mediaPopupActive = true;
      mediaPopupTimer.restart();
    }
  }

  Timer {
    id: mediaPopupTimer
    interval: 3500
    repeat: false
    onTriggered: mediaPopupActive = false
  }

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
      property alias isCalendarOpen: calendarMenu.open
      property alias isAppLauncherOpen: appLauncher.open
      property alias isClipboardOpen: clipboardLauncher.open
      property alias isWallpaperOpen: wallpaperLauncher.open
      property alias isPackageSearcherOpen: packageSearcher.open
      property alias isOverviewOpen: overviewController.open
      property bool isRightPanelOpen: isControlPanelOpen || isWifiOpen || isBtOpen
      property bool isAnyPanelOpen: isRightPanelOpen || isCalendarOpen || isAppLauncherOpen || isClipboardOpen || isWallpaperOpen || isPackageSearcherOpen || isOverviewOpen || polkitAgent.isActive

      function closeAllPanelsExcept(panel) {
        if (panel !== "appLauncher") bar.isAppLauncherOpen = false;
        if (panel !== "clipboardLauncher") bar.isClipboardOpen = false;
        if (panel !== "wallpaperLauncher") bar.isWallpaperOpen = false;
        if (panel !== "packageSearcher") bar.isPackageSearcherOpen = false;
        if (panel !== "controlPanel") bar.isControlPanelOpen = false;
        if (panel !== "calendarMenu") bar.isCalendarOpen = false;
        if (panel !== "wifi") bar.isWifiOpen = false;
        if (panel !== "bt") bar.isBtOpen = false;
        if (panel !== "overview") bar.isOverviewOpen = false;
      }

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
        onCleared: bar.closeAllPanelsExcept("")
      }

      OverviewModule.OverviewController {
        id: overviewController
        activeMonitor: bar.screen
        onOpenChanged: if (open) bar.closeAllPanelsExcept("overview")
      }

      anchors {
        top: true
        left: true
        right: true
      }






      Item {
        anchors.fill: parent

        BarIsland {
          id: leftIsland
          anchors.left: parent.left
          anchors.leftMargin: 8
          anchors.top: parent.top
          anchors.topMargin: (theme.barHeight - theme.islandHeight) / 2
          
          implicitWidth: bar.isOverviewOpen ? (bar.width - 32) : leftRow.implicitWidth + theme.islandPaddingH * 2
          implicitHeight: bar.isOverviewOpen ? Math.round(bar.height * 0.85) : theme.islandHeight
          customRadius: bar.isOverviewOpen ? theme.radiusLarge : theme.radiusPill
          z: bar.isOverviewOpen ? 10 : 1

          Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
          Behavior on implicitHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
          Behavior on customRadius { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

          Item {
            anchors.fill: parent

            Row {
              id: leftRow
              anchors.centerIn: parent
              spacing: theme.gap
              opacity: bar.isOverviewOpen ? 0 : 1
              scale: bar.isOverviewOpen ? 0.9 : 1
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

              WorkspaceList {
                screen: bar.screen
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            OverviewModule.WorkspaceGrid {
              id: workspaceGrid
              anchors.fill: parent
              workspaces: overviewController.workspaces
              allClients: overviewController.clients
              activeMonitor: bar.screen
              
              opacity: bar.isOverviewOpen ? 1 : 0
              scale: bar.isOverviewOpen ? 1 : 0.95
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
              
              onVisibleChanged: {
                if (visible) {
                  workspaceGrid.forceActiveFocus()
                }
              }
              
              onCloseRequested: bar.closeAllPanelsExcept("")
            }
          }
        }

        BarIsland {
          id: centerIsland
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: (theme.barHeight - theme.islandHeight) / 2
          
          implicitWidth: (bar.isAppLauncherOpen || bar.isClipboardOpen || bar.isWallpaperOpen || bar.isPackageSearcherOpen) ? Math.round(bar.width * 0.8) :
                         polkitAgent.isActive ? 400 :
                         root.osd.active ? 240 : (root.mediaPopupActive ? 280 : centerRow.implicitWidth + theme.islandPaddingH * 2)
          implicitHeight: bar.isAppLauncherOpen ? 680 :
                          bar.isClipboardOpen ? 660 :
                          bar.isWallpaperOpen ? Math.round(bar.height * 0.8) :
                          bar.isPackageSearcherOpen ? Math.round(bar.height * 0.8) :
                          polkitAgent.isActive ? 220 :
                          theme.islandHeight
          customRadius: (bar.isAppLauncherOpen || bar.isClipboardOpen || bar.isWallpaperOpen || bar.isPackageSearcherOpen || polkitAgent.isActive) ? theme.radiusLarge : theme.radiusPill
          z: (bar.isAppLauncherOpen || bar.isClipboardOpen || bar.isWallpaperOpen || bar.isPackageSearcherOpen || polkitAgent.isActive) ? 10 : 1

          Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
          Behavior on implicitHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
          Behavior on customRadius { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

          Item {
            anchors.fill: parent

            Row {
              id: centerRow
              anchors.centerIn: parent
              opacity: (polkitAgent.isActive || root.osd.active || root.mediaPopupActive || bar.isAppLauncherOpen || bar.isClipboardOpen || bar.isWallpaperOpen || bar.isPackageSearcherOpen) ? 0 : 1
              scale: (polkitAgent.isActive || root.osd.active || root.mediaPopupActive || bar.isAppLauncherOpen || bar.isClipboardOpen || bar.isWallpaperOpen || bar.isPackageSearcherOpen) ? 0.9 : 1
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

              ClockWidget {}
            }

            Item {
              id: osdContainer
              anchors.fill: parent
              opacity: root.osd.active && !polkitAgent.isActive ? 1 : 0
              scale: root.osd.active && !polkitAgent.isActive ? 1 : 0.9
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

              // Has Level (Volume, Brightness)
              Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12
                visible: root.osd.hasLevel

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.osd.icon
                  color: theme.accent
                  font.pixelSize: 16
                }

                Item {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - 16 - 12 - 32 // Remaining width minus icon (16), spacing (12), and text (32)
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

              // No Level (WiFi, Airplane Mode, Silent)
              Row {
                anchors.centerIn: parent
                spacing: 8
                visible: !root.osd.hasLevel

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.osd.icon
                  color: theme.accent
                  font.pixelSize: 16
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.osd.title
                  color: theme.foreground
                  font.pixelSize: 13
                  font.weight: Font.DemiBold
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "--"
                  color: theme.muted
                  font.pixelSize: 13
                  font.weight: Font.Medium
                  visible: root.osd.detail.length > 0
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.osd.detail
                  color: theme.muted
                  font.pixelSize: 13
                  font.weight: Font.Medium
                  visible: root.osd.detail.length > 0
                }
              }
            }

            // Media Popup
            Row {
              id: mediaRow
              anchors.centerIn: parent
              spacing: 12
              opacity: root.mediaPopupActive && !root.osd.active && !polkitAgent.isActive ? 1 : 0
              scale: root.mediaPopupActive && !root.osd.active && !polkitAgent.isActive ? 1 : 0.9
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

              Rectangle {
                width: 26
                height: 26
                radius: 13
                color: theme.surfaceHover
                clip: true
                anchors.verticalCenter: parent.verticalCenter

                Image {
                  anchors.fill: parent
                  source: root.activePlayer ? root.activePlayer.trackArtUrl : ""
                  fillMode: Image.PreserveAspectCrop
                  visible: String(source).length > 0
                }

                Text {
                  anchors.centerIn: parent
                  visible: !parent.children[0].visible
                  text: "󰎆"
                  color: theme.muted
                  font.pixelSize: 12
                }
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 200)
                text: root.activePlayer ? root.activePlayer.trackTitle : ""
                color: theme.foreground
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
              }
            }

            PolkitPrompt {
              anchors.fill: parent
              flow: polkitAgent.flow
              opacity: polkitAgent.isActive ? 1 : 0
              scale: polkitAgent.isActive ? 1 : 0.9
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
            }

            AppLauncher {
              id: appLauncher
              onOpenChanged: if (open) bar.closeAllPanelsExcept("appLauncher")
              parentWindow: bar
              anchors.fill: parent
              scale: open ? 1 : 0.95
              opacity: open ? 1 : 0
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
            }

            ClipboardLauncher {
              id: clipboardLauncher
              onOpenChanged: if (open) bar.closeAllPanelsExcept("clipboardLauncher")
              parentWindow: bar
              anchors.fill: parent
              scale: open ? 1 : 0.95
              opacity: open ? 1 : 0
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
            }

            WallpaperLauncher {
              id: wallpaperLauncher
              onOpenChanged: if (open) bar.closeAllPanelsExcept("wallpaperLauncher")
              parentWindow: bar
              anchors.fill: parent
              scale: open ? 1 : 0.95
              opacity: open ? 1 : 0
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
            }

            PackageSearcher {
              id: packageSearcher
              onOpenChanged: if (open) bar.closeAllPanelsExcept("packageSearcher")
              parentWindow: bar
              anchors.fill: parent
              scale: open ? 1 : 0.95
              opacity: open ? 1 : 0
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
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

          customRadius: bar.isRightPanelOpen ? theme.radiusLarge : theme.radiusPill
          z: bar.isRightPanelOpen ? 10 : 1
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
              opacity: bar.isRightPanelOpen ? 0 : 1
              scale: bar.isRightPanelOpen ? 0.9 : 1
              visible: opacity > 0
              Behavior on opacity { NumberAnimation { duration: 150 } }
              Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

              ConnectivityButtons {
                id: connectivityBtns
                parentWindow: bar
                island: rightIsland
                anchors.verticalCenter: parent.verticalCenter
                onWifiPopupOpenChanged: if (wifiPopupOpen) bar.closeAllPanelsExcept("wifi")
                onBluetoothPopupOpenChanged: if (bluetoothPopupOpen) bar.closeAllPanelsExcept("bt")
              }
              BatteryIndicator { anchors.verticalCenter: parent.verticalCenter }
              Tray { parentWindow: bar; anchors.verticalCenter: parent.verticalCenter }
              BarIconButton { icon: "󰅇"; active: clipboardLauncher.open; anchors.verticalCenter: parent.verticalCenter; onClicked: clipboardLauncher.open = !clipboardLauncher.open }
              SidebarButton { anchors.verticalCenter: parent.verticalCenter; active: controlPanel.open; onClicked: controlPanel.open = !controlPanel.open }
            }

            ControlPanel {
              id: controlPanel
              onOpenChanged: if (open) bar.closeAllPanelsExcept("controlPanel")
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              panelScreen: bar.screen
              notificationServer: root.notificationServer
              notificationCenter: root.notificationCenter
              osd: root.osd
              brightnessTracker: root.brightnessTracker
              
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
      
      CalendarMenu {
        id: calendarMenu
        onOpenChanged: if (open) bar.closeAllPanelsExcept("calendarMenu")
        parentWindow: bar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: theme.barHeight + 8
      }
    }
  }
}
