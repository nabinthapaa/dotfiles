// WorkspaceList.qml — Occupied workspaces only, with number labels.
// Active workspace → filled accent pill, inactive → subtle dot with number.
import Quickshell.Hyprland
import QtQuick
import "../../../shared"

Row {
  id: root

  required property var screen

  spacing: 4

  Theme { id: theme }

  readonly property var monitor: Hyprland.monitorFor(screen)

  // All positive-id workspaces that belong to this monitor, sorted by id.
  readonly property var workspaces: {
    const all = Hyprland.workspaces.values;
    const result = [];
    for (let i = 0; i < all.length; i++) {
      const ws = all[i];
      if (!ws || ws.id <= 0) continue;
      if (root.monitor && ws.monitor && ws.monitor !== root.monitor
          && ws.monitor.name !== root.monitor.name) continue;
      result.push(ws);
    }
    result.sort((a, b) => a.id - b.id);
    return result;
  }

  Repeater {
    model: root.workspaces

    Rectangle {
      id: wsBtn

      required property var modelData

      readonly property int wsId: modelData.id
      readonly property bool active: root.monitor
        && root.monitor.activeWorkspace
        && root.monitor.activeWorkspace.id === wsId
      readonly property bool urgent: modelData.urgent ?? false

      // Active: wide labeled pill.  Inactive: small circle with number.
      width: active ? label.implicitWidth + 16 : 22
      height: 22
      radius: theme.radiusPill

      color: urgent
        ? theme.urgent
        : active
          ? theme.accent
          : hoverArea.containsMouse
            ? theme.surfaceHigh
            : theme.surfaceHover

      border.width: active ? 0 : 1
      border.color: Qt.rgba(theme.border.r, theme.border.g, theme.border.b, 0.5)

      Behavior on width {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }

      Behavior on color {
        ColorAnimation { duration: 120 }
      }

      Text {
        id: label
        anchors.centerIn: parent
        text: wsBtn.wsId
        font.pixelSize: 11
        font.weight: wsBtn.active ? Font.Bold : Font.Medium
        color: wsBtn.urgent
          ? theme.background
          : wsBtn.active
            ? theme.accentForeground
            : theme.muted

        Behavior on color {
          ColorAnimation { duration: 120 }
        }
      }

      MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch("workspace", String(wsBtn.wsId))
      }
    }
  }
}
