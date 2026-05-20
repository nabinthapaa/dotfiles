import Quickshell.Hyprland
import QtQuick
import "../../../shared"

Row {
  id: root

  required property var screen

  spacing: theme.gap / 2

  Theme {
    id: theme
  }

  readonly property var monitor: Hyprland.monitorFor(screen)
  readonly property var workspaces: Hyprland.workspaces.values
    .filter(workspace => workspace && workspace.id > 0 && root.belongsToMonitor(workspace))
    .sort((a, b) => a.id - b.id)

  function belongsToMonitor(workspace) {
    if (!root.monitor || !workspace.monitor) {
      return true;
    }

    return workspace.monitor === root.monitor
      || workspace.monitor.name === root.monitor.name;
  }

  Repeater {
    model: root.workspaces

    Rectangle {
      id: button

      required property var modelData

      readonly property int workspaceId: modelData.id
      readonly property var workspace: modelData
      readonly property bool active: root.monitor
        && root.monitor.activeWorkspace
        && root.monitor.activeWorkspace.id === workspaceId
      readonly property bool occupied: workspace !== undefined
      readonly property bool urgent: occupied && workspace.urgent

      width: active ? 34 : 24
      height: theme.controlSize
      radius: theme.radiusLarge
      color: urgent ? theme.urgent : active ? theme.accentContainer : hover.containsMouse ? theme.surfaceHover : "transparent"
      border.width: occupied && !active ? 1 : 0
      border.color: theme.border

      Behavior on width {
        NumberAnimation {
          duration: 140
          easing.type: Easing.OutCubic
        }
      }

      Text {
        anchors.centerIn: parent
        text: button.workspaceId
        color: button.active ? theme.accentContainerForeground : button.urgent ? theme.background : button.occupied ? theme.foreground : theme.muted
        font.pixelSize: 12
        font.weight: button.active ? Font.DemiBold : Font.Medium
      }

      MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("workspace " + button.workspaceId)
      }
    }
  }
}
