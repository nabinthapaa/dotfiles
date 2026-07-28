import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import "../../../../shared"

Grid {
  id: root
  
  required property var notificationCenter
  required property var osd
  required property var panelScreen
  
  width: parent ? parent.width : 352
  columns: 2
  columnSpacing: 12
  rowSpacing: 12

  Theme { id: theme }

  property bool nightLightEnabled: false

  function interactiveSurface(active, hovered) {
    return active ? theme.accentContainer : hovered ? theme.surfaceHover : theme.surfaceHigh;
  }

  function interactiveForeground(active) {
    return active ? theme.accentContainerForeground : theme.foreground;
  }

  function interactiveSupport(active) {
    return active ? theme.accentContainerForeground : theme.muted;
  }

  function connectedWifiName() {
    const devices = Networking.devices.values;
    for (let i = 0; i < devices.length; i++) {
      const device = devices[i];
      if (!device.networks) continue;
      const networks = device.networks.values;
      for (let j = 0; j < networks.length; j++) {
        if (networks[j].connected) return networks[j].name;
      }
    }
    return "";
  }

  function connectedBluetoothName() {
    if (!Bluetooth.defaultAdapter) return "";
    const devices = Bluetooth.defaultAdapter.devices.values.filter(d => d.connected);
    if (devices.length === 0) return "";
    return devices.map(d => d.deviceName || d.name).join(", ");
  }

  function controlActive(kind) {
    if (kind === "wifi") return Networking.wifiEnabled;
    if (kind === "bluetooth") return Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled;
    if (kind === "night") return root.nightLightEnabled;
    if (kind === "dnd") return root.notificationCenter.dndEnabled;
    return false;
  }

  function controlStatus(kind) {
    if (kind === "wifi") {
      const name = connectedWifiName();
      return name === "" ? "Not connected" : name;
    }
    if (kind === "bluetooth") {
      const name = connectedBluetoothName();
      return name === "" ? "Not connected" : name;
    }
    if (kind === "night") return root.nightLightEnabled ? "On" : "Off";
    if (kind === "dnd") return root.notificationCenter.dndEnabled ? "On" : "Off";
    return "";
  }

  function toggleControl(kind) {
    if (kind === "wifi") {
      Networking.wifiEnabled = !Networking.wifiEnabled;
      root.osd.showAirplane(!Networking.wifiEnabled);
    } else if (kind === "bluetooth" && Bluetooth.defaultAdapter) {
      Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
    } else if (kind === "night") {
      setNightLight(!root.nightLightEnabled);
    } else if (kind === "dnd") {
      root.notificationCenter.dndEnabled = !root.notificationCenter.dndEnabled;
      root.osd.showSilent(root.notificationCenter.dndEnabled);
    }
  }

  function setNightLight(enabled) {
    if (enabled) {
      Quickshell.execDetached(["sh", "-c", "hyprctl hyprsunset temperature 4500 || hyprsunset -t 4500"]);
      root.nightLightEnabled = true;
    } else {
      Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"]);
      root.nightLightEnabled = false;
    }
    nightStatusTimer.restart();
  }

  function refreshNightLightStatus() {
    nightStatusProc.running = false;
    nightStatusProc.running = true;
  }

  Timer { id: nightStatusTimer; interval: 800; running: true; repeat: true; onTriggered: root.refreshNightLightStatus() }

  Process {
    id: nightStatusProc
    command: ["sh", "-c", "hyprctl -j hyprsunset 2>/dev/null || true"]
    stdout: StdioCollector {
      onStreamFinished: {
        const output = text.trim();
        if (output.length === 0) { root.nightLightEnabled = false; return; }
        try {
          const status = JSON.parse(output);
          root.nightLightEnabled = status.identity === false || (typeof status.temperature === "number" && status.temperature < 6500);
        } catch (error) {}
      }
    }
  }

  Repeater {
    model: [
      { key: "wifi", label: "Wi-Fi", icon: "󰖩" },
      { key: "bluetooth", label: "Bluetooth", icon: "󰂯" },
      { key: "night", label: "Night Light", icon: "󰖔" },
      { key: "dnd", label: "Do Not Disturb", icon: "󰂛" }
    ]

    delegate: Rectangle {
      required property var modelData
      width: (parent.width - 12) / 2
      height: 64
      radius: theme.radiusLarge
      color: root.interactiveSurface(root.controlActive(modelData.key), controlArea.containsMouse)
      
      Behavior on color { ColorAnimation { duration: 150 } }

      Row {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        spacing: 12

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.icon
          color: root.interactiveForeground(root.controlActive(modelData.key))
          font.pixelSize: 20
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - 32
          spacing: 2

          Text {
            width: parent.width
            text: modelData.label
            color: root.interactiveForeground(root.controlActive(modelData.key))
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: root.controlStatus(modelData.key)
            visible: text.length > 0
            color: root.interactiveSupport(root.controlActive(modelData.key))
            font.pixelSize: 10
            font.weight: Font.Medium
            elide: Text.ElideRight
          }
        }
      }

      MouseArea {
        id: controlArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleControl(modelData.key)
      }
    }
  }
}
