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

  function getIconForClass(cls) {
    if (!cls) return "";
    cls = String(cls).toLowerCase();
    if (cls.indexOf("firefox") !== -1 || cls.indexOf("zen") !== -1) return "";
    if (cls.indexOf("chrome") !== -1 || cls.indexOf("brave") !== -1) return "";
    if (cls.indexOf("kitty") !== -1 || cls.indexOf("alacritty") !== -1 || cls.indexOf("term") !== -1 || cls.indexOf("ghostty") !== -1) return "";
    if (cls.indexOf("code") !== -1 || cls.indexOf("cursor") !== -1) return "";
    if (cls.indexOf("discord") !== -1 || cls.indexOf("vesktop") !== -1) return "";
    if (cls.indexOf("spotify") !== -1) return "";
    if (cls.indexOf("thunar") !== -1 || cls.indexOf("nemo") !== -1 || cls.indexOf("dolphin") !== -1 || cls.indexOf("files") !== -1) return "";
    if (cls.indexOf("slack") !== -1) return "";
    if (cls.indexOf("obs") !== -1) return "";
    if (cls.indexOf("steam") !== -1) return "";
    if (cls.indexOf("telegram") !== -1) return "";
    return ""; // generic window
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

      readonly property var latestToplevel: modelData.toplevels && modelData.toplevels.values.length > 0 ? modelData.toplevels.values[modelData.toplevels.values.length - 1] : null
      readonly property string clientClass: {
        if (!latestToplevel) return "";
        if (latestToplevel.wayland && latestToplevel.wayland.appId) return latestToplevel.wayland.appId;
        if (latestToplevel.lastIpcObject && latestToplevel.lastIpcObject.class) return latestToplevel.lastIpcObject.class;
        return "";
      }
      
      readonly property string wsIcon: root.getIconForClass(clientClass)

      // Active: wide labeled pill.  Inactive: small circle with number/icon.
      width: active ? label.implicitWidth + 16 : 24
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
        text: (wsBtn.active && wsBtn.wsIcon) ? wsBtn.wsIcon : wsBtn.wsId
        font.pixelSize: (wsBtn.active && wsBtn.wsIcon) ? 13 : 11
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
