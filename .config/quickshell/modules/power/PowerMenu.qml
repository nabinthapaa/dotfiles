import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../../shared"

Scope {
  id: root

  readonly property var actions: [
    { key: "lock", label: "Lock", icon: "", command: ["hyprlock"] },
    { key: "exit", label: "Exit", icon: "󰍃", command: ["hyprctl", "dispatch", "exit"] },
    { key: "hibernate", label: "Hibernate", icon: "󰒲", command: ["systemctl", "hibernate"] },
    { key: "suspend", label: "Suspend", icon: "󰤄", command: ["systemctl", "suspend"] },
    { key: "reboot", label: "Reboot", icon: "󰜉", command: ["systemctl", "reboot"] },
    { key: "shutdown", label: "Shutdown", icon: "⏻", command: ["shutdown", "now"] }
  ]

  Theme {
    id: theme
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: menu

      required property var modelData
      property bool open: false
      property int selectedIndex: 0
      readonly property var hyprMonitor: Hyprland.monitorFor(screen)
      readonly property string ipcTargetName: hyprMonitor ? hyprMonitor.name : screen.name

      screen: modelData
      visible: open
      color: "transparent"
      focusable: true
      aboveWindows: true
      exclusionMode: ExclusionMode.Ignore

      anchors {
        top: true
        right: true
        bottom: true
        left: true
      }

      onOpenChanged: {
        if (open) {
          selectedIndex = 0;
          Qt.callLater(() => overlay.forceActiveFocus());
        }
      }

      function cycle(direction) {
        selectedIndex = (selectedIndex + direction + root.actions.length) % root.actions.length;
      }

      function runSelected() {
        runAction(root.actions[selectedIndex]);
      }

      function runAction(action) {
        if (!action) {
          return;
        }

        open = false;
        Quickshell.execDetached(action.command);
      }

      IpcHandler {
        target: "powerMenu." + menu.ipcTargetName

        function open(): void {
          menu.open = true;
        }

        function close(): void {
          menu.open = false;
        }

        function toggle(): void {
          menu.open = !menu.open;
        }

        function isOpen(): bool {
          return menu.open;
        }
      }

      Item {
        id: overlay

        anchors.fill: parent
        focus: menu.open
        opacity: menu.open ? 1 : 0
        scale: menu.open ? 1 : 0.95

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

        Keys.onEscapePressed: menu.open = false
        Keys.onReturnPressed: menu.runSelected()
        Keys.onEnterPressed: menu.runSelected()
        Keys.onPressed: event => {
          if (event.key === Qt.Key_Tab) {
            menu.cycle(event.modifiers & Qt.ShiftModifier ? -1 : 1);
            event.accepted = true;
          } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
            menu.cycle(1);
            event.accepted = true;
          } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            menu.cycle(-1);
            event.accepted = true;
          }
        }

        Image {
          anchors.fill: parent
          source: "file://"+ Quickshell.env("HOME") +"/.cache/wal/blurred_wallpaper.png"
          fillMode: Image.PreserveAspectCrop
          cache: false
        }

        Rectangle {
          anchors.fill: parent
          color: theme.background
          opacity: 0.64
        }

        MouseArea {
          anchors.fill: parent
          onClicked: menu.open = false
        }

        Grid {
          id: actionGrid

          anchors.centerIn: parent
          width: Math.min(parent.width - 64, 760)
          columns: 3
          columnSpacing: 16
          rowSpacing: 16

          Repeater {
            model: root.actions

            delegate: Rectangle {
              id: actionButton

              required property var modelData
              required property int index

              readonly property bool selected: menu.selectedIndex === index

              width: (actionGrid.width - actionGrid.columnSpacing * (actionGrid.columns - 1)) / actionGrid.columns
              height: 160
              radius: theme.radiusLarge
              color: selected ? theme.accentContainer : actionArea.containsMouse ? theme.surfaceHover : theme.surfaceHigh
              border.width: selected ? 2 : 1
              border.color: selected ? theme.accent : theme.border

              Column {
                anchors.centerIn: parent
                width: parent.width - 24
                spacing: 12

                Text {
                  width: parent.width
                  text: actionButton.modelData.icon
                  color: actionButton.selected ? theme.accentContainerForeground : theme.foreground
                  horizontalAlignment: Text.AlignHCenter
                  font.pixelSize: 48
                }

                Text {
                  width: parent.width
                  text: actionButton.modelData.label
                  color: actionButton.selected ? theme.accentContainerForeground : theme.foreground
                  elide: Text.ElideRight
                  horizontalAlignment: Text.AlignHCenter
                  font.pixelSize: 14
                  font.weight: Font.DemiBold
                }
              }

              MouseArea {
                id: actionArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: menu.selectedIndex = index
                onClicked: menu.runAction(actionButton.modelData)
              }
            }
          }
        }
      }
    }
  }
}
