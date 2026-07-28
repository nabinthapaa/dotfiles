import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../../../shared"
import "controlpanel"

Item {
  id: root

  required property var panelScreen
  required property var notificationServer
  required property var osd
  required property var notificationCenter
  required property var brightnessTracker
  property bool open: false
  property bool powerPageOpen: false

  implicitWidth: 380
  implicitHeight: contentColumn.implicitHeight + 28

  Theme {
    id: theme
  }

  IpcHandler {
    target: "controlPanel." + root.panelScreen.name
    function open(): void { root.open = true; }
    function close(): void { root.open = false; }
    function toggle(): void { root.open = !root.open; }
    function isOpen(): bool { return root.open; }
    function screen(): string { return root.panelScreen.name; }
  }

  onOpenChanged: {
    if (open) {
      powerPageOpen = false;
      panel.forceActiveFocus();
    }
  }

  Timer {
    id: screenshotMenuTimer; interval: 220; repeat: false;
    onTriggered: {
      const monitor = Hyprland.monitorFor(root.panelScreen);
      if (monitor) { Quickshell.execDetached(["qs", "-p", "~/dotfiles/.config/quickshell/", "ipc", "call", "screenshotMenu." + monitor.name, "open"]); }
    }
  }

  Item {
    id: panel
    anchors.fill: parent
    
    // Smooth opacity fade
    opacity: root.open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    Keys.onEscapePressed: root.open = false

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    Column {
      id: contentColumn
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 14
      spacing: 14

      WeatherWidget {
        width: parent.width
      }

      QuickToggles {
        width: parent.width
        notificationCenter: root.notificationCenter
        osd: root.osd
        panelScreen: root.panelScreen
      }

      SlidersBlock {
        width: parent.width
        osd: root.osd
        brightnessTracker: root.brightnessTracker
      }

      MediaCarousel {
        width: parent.width
      }
    }
  }
}
